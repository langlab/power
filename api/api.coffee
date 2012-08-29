
cluster = require 'cluster'
numCPUs = require('os').cpus().length
moment = require 'moment'

_ = require 'underscore'
CFG = require '../conf'

# rec upload handler
uploadServer = require './lib/recUploads'


# data classes used to create api services
Student = require './db/student'
File = require './db/file'
User = require './db/user'
Lab = require './lib/lab'
Activity = require './db/activity'

studentAuth = require './lib/studentAuth'

# access to the api via socket connection

io = require 'socket.io'

redis = require 'redis'
RedisStore = require 'socket.io/lib/stores/redis'

red = redis.createClient()

util = require 'util'

if cluster.isMaster
  
  for i in [1..numCPUs]
    cluster.fork()

  cluster.on 'exit', (worker)->
    console.log('worker ' + worker.process.pid + ' died')


  # things to do only once in the master process

  Student.setOffline 'all'

  tasks = [
    { freq: 5000, func: require './tasks/cacheTwitterFollowers' }
  ]
    
  doEvery = (someTime,action)->
    setInterval action, someTime

  for task in tasks
    {freq,func} = task
    doEvery freq, func

else
  
  uploadServer.listen 9999
  uploadServer.on 'rec:upload', (fileData)->
    File.recUpload fileData

  pub    = redis.createClient()
  sub    = redis.createClient()
  client = redis.createClient()

  User.sio = Student.sio = sio = io.listen 8282


  sio.set 'store', new RedisStore {
    redisPub : pub
    redisSub : sub
    redisClient : client
  }

  sio.getSockFor = (userId)->
    sio.sockets.clients("self:#{userId}")[0]


  #config and authorization
  sio.configure ->

    sio.set 'reconnection limit', 3000
    #sio.set 'origins','*:*'

    sio.set 'authorization', (hs,cb)->
      if hs.query?.secret is 'claude'
        hs.role = 'admin'
        #console.log 'admin connected'
        cb null, true
      else

        # make sure the user is logged in before accepting a connection
        # look for the sessionId cookie

        cookieStr = _.find hs.headers.cookie?.split(';'), (i)-> /sessionId/.test(i)
        
        ssid = (unescape cookieStr?.split('=')[1])
        #console.log "ssid: #{ssid}"

        # find the session in redis
        red.get "sess:#{ssid}", (err, sessStr)->
          sess = JSON.parse sessStr
          #console.log 'sess:',sess
          hs.sess = sess
          hs.userId = hs.sess?.student?._id ? hs.sess.auth?.userId
          
          # set roles for DB access

          if (sess?.auth?.twitter and hs.headers.referer is "https://#{CFG.HOST()}/")

            # get the user
            User.findById hs.sess.auth.userId, (err,user)->
              #console.log 'user: ',user
              if user and not err
                hs.role = 'teacher'
                hs.user = user
                cb null, true

          else
            hs.role = 'student'
            hs.student = hs.sess.student
            cb null, true


  # db service setup
  services =
    student: Student
    file: File
    user: User
    lab: Lab


  sio.on 'connection', (socket)->
    # pass any incoming sync request to the data class for handling
    # each service must have a .sync method

    socket.on 'sio', (cb)->
      info = {}
      for room,sockId of sio.sockets.manager.rooms
        info[room] = 
          socket: sockId
          clients: sio.sockets.clients(room).length

      cb info

      


    {sess,userId,role,user,student} = socket.handshake

    socket.set 'userId', userId

    # keep track of the sockets by userId
    if userId
      #console.log 'user joining self socket: ',userId
      socket.join "self:#{userId}"
      socket.join "lab:#{userId}"

    # console.log 'hs sess', sess
    
    if role is 'student'
      Student.setOnline userId, (err, student)->
        if student.control
          Lab.bringStudent sio, student


    else if role is 'teacher'
      User.setOnline userId



    # most calls from a web client come through here via backbone sync
    socket.on 'sync', (service,data,cb)->
      
      data.options ?= {}

      # set identity of client before accessing the db
      _.extend data.options, {
        user: user
        userId: userId
        role: role
        student: student
      }

      
      # pass access to sockets for realtime lab interaction
      if service is 'lab' 
        #console.log 'lab: ',data
        data.options.socket = socket
        data.options.sio = sio      

      services[service].sync data, cb


    socket.on 'auth', (data, cb)->
      studentAuth.signin data, cb



    # automatically set offline status for teachers/students when their clients disconnect
    socket.on 'disconnect', (x,y,z)->
      if role is 'student'
        Student.setOffline userId
      else if role is 'teacher'
        User.setOffline userId



  # when a teacher's piggyBank changes (because of an student transfer or purchase), send a notice to that user
  User.on 'change:piggyBank', (user)->
    sio.sockets.in("self:#{user._id}").emit 'sync','user', { method: 'piggyBank', model: user }

  # when a student comes on/offline, notify the teacher
  Student.on 'change:online', (student)->
    sio.sockets.in("self:#{student.teacherId}").emit 'sync', 'student', { method: 'online', model: student }

  # when a student's piggyBank changes, notify the student's client
  Student.on 'change:piggyBank', (student)->
    sio.sockets.in("self:#{student._id}").emit 'sync', 'student', { method: 'piggyBank', model: student }

  Student.on 'change:help', (student)->
    sio.sockets.in("self:#{student.teacherId}").emit 'sync', 'student', { method: 'help', model: student }


  Student.on 'change:control', (student)->
    #console.log 'change:control', student

    # take all student's clients out of the teacher's lab room
    stuClients = sio.sockets.clients("self:#{student._id}")
    for stu in stuClients
      #console.log stu.id
      if student.control
        #console.log 'joining'
        stu.join "lab:#{student.teacherId}"
      else
        #console.log 'leaving'
        stu.leave "lab:#{student.teacherId}"

    # notify the student's clients
    User.findById student.teacherId, (err,user)=>
      sio.sockets.in("self:#{student._id}").emit 'sync', 'lab', { 
        method: if student.control then 'join' else 'leave'
        model: user.labState
      }

    # notify the teacher's client
    sio.sockets.in("self:#{student.teacherId}").emit 'sync', 'student', { method: 'control', model: student }

  # when a file prep progress changes, update the teacher's client
  File.on 'change:progress', (file)->
    sio.sockets.in("self:#{file.owner}").emit 'sync', 'file', { method: 'progress', model: file }

  File.on 'new', (file)->
    #console.log 'emitting new file',file
    sio.sockets.in("self:#{file.owner}").emit 'sync', 'file', { method: 'create', model: file }


    









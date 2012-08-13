
_ = require 'underscore'
CFG = require '../conf'

# access to the api via socket connection

io = require 'socket.io'
red = require('redis').createClient()

util = require 'util'

sio = io.listen 8282

# data classes used to create api services
Student = require './db/student'
File = require './db/file'
User = require './db/user'
Lab = require './db/lab'

studentAuth = require './lib/studentAuth'

connectedSockets = {}

sio.configure ->

  sio.set 'reconnection limit', 3000
  #sio.set 'origins','*:*'

  sio.set 'authorization', (hs,cb)->

    # make sure the user is logged in before accepting a connection
    # look for the sessionId cookie

    cookieStr = _.find hs.headers.cookie?.split(';'), (i)-> /sessionId/.test(i)
    
    ssid = (unescape cookieStr?.split('=')[1])
    console.log "ssid: #{ssid}"

    # find the session in redis
    red.get "sess:#{ssid}", (err, sessStr)->
      sess = JSON.parse sessStr
      console.log 'sess:',sess
      hs.sess = sess
      hs.userId = hs.sess.student?._id ? hs.sess.auth?.userId
      hs.student = hs.sess.student
      # set roles for DB access

      console.log 'host: ',hs.headers.referer
      if sess?.auth?.twitter and hs.headers.referer is "https://#{CFG.HOST()}/"

        # get the user
        User.findById hs.sess.auth.userId, (err,user)->
          console.log 'user: ',user
          if user and not err
            hs.role = 'teacher'
            hs.user = user
            cb null, true

      else
        cb null, true

services =
  student: Student
  file: File
  user: User
  lab: Lab


sio.on 'connection', (socket)->
  # pass any incoming sync request to the data class for handling
  # each service must have a .sync method

  {sess,userId,role,user,student} = socket.handshake

  if userId then connectedSockets[userId] = socket

  console.log 'hs sess', sess
  
  if student
    console.log 'student signing in: ',userId
    Student.signIn userId

  if user
    console.log 'teacher signing in: ',userId
    User.signIn userId

  socket.on 'sync', (service,data,cb)->
    data.options ?= {}
    _.extend data.options, {
      user: user
      userId: userId
      role: role
    }
    services[service].sync data, cb
    console.log 'sync recvd: ', util.inspect data

  socket.on 'auth', (data, cb)->
    studentAuth.signin data, cb

  socket.on 'disconnect', (x,y,z)->
    delete connectedSockets[userId]
    if student
      Student.signOut userId
    if user
      User.signOut userId



# when a teacher's piggyBank changes (because of an student transfer or purchase), send a notice to that user
User.on 'change:piggyBank', (user)->
  connectedSockets[user._id]?.emit 'sync','user', { method: 'piggyBank', model: user }

# when a student comes on/offline, notify the teacher
Student.on 'change:online', (student)->
  connectedSockets[student.teacherId]?.emit 'sync', 'student', { method: 'online', model: student }

Student.on 'change:piggyBank', (student)->
  connectedSockets[student._id]?.emit 'sync', 'student', { method: 'piggyBank', model: student }

File.on 'change:progress', (file)->
  console.log 'change:progress',file
  connectedSockets[file.owner]?.emit 'sync', 'file', { method: 'progress', model: file }




tasks = [
  { freq: 5000, func: require './tasks/cacheTwitterFollowers' }
]
  
doEvery = (someTime,action)->
  setInterval action, someTime

for task in tasks
  {freq,func} = task
  doEvery freq, func



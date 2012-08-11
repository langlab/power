
_ = require 'underscore'
CFG = require '../conf'

# access to the api via socket connection

io = require 'socket.io'
red = require('redis').createClient()

util = require 'util'

sio = io.listen 8080

# data classes used to create api services
Student = require './db/student'
File = require './db/file'
User = require './db/user'

studentAuth = require './lib/studentAuth'

connectedSockets = {}

sio.configure ->

  sio.set 'authorization', (hs,cb)->
    if hs.headers.host is 'localhost'
      cb null,true
    else

      # make sure the user is logged in before accepting a connection
      # look for the sessionId cookie

      cookieStr = _.find hs.headers.cookie?.split(';'), (i)-> /sessionId/.test(i)
      
      ssid = (unescape cookieStr?.split('=')[1])
      console.log "ssid: #{ssid}"

      # find the session in redis
      red.get "sess:#{ssid}", (err, sessStr)->
        sess = JSON.parse sessStr
        console.log util.inspect sess
        hs.sess = sess
        
        if sess.auth?.twitter and hs.headers.referer is "http://#{CFG.HOST()}/"
          hs.role = 'teacher'

          # get the user
          User.findById hs.sess.auth.userId, (err,user)->
            if user
              hs.userId = user._id
              hs.isTeacher = true
              hs.user = user
              cb null, true

        else if sess.role is 'student'

          Student.findById hs.sess.student._id, (err,student)->
            if student
              hs.role = 'student'
              hs.userId = student._id
              hs.isStudent = true
              hs.student = student
              cb null, true

        else
          cb null, true

services =
  student: Student
  file: File
  user: User


sio.on 'connection', (socket)->
  # pass any incoming sync request to the data class for handling
  # each service must have a .sync method

  if (sid = socket.handshake.userId) then connectedSockets[sid] = socket

  if socket.handshake.role is 'student'
    Student.signIn sid

  if socket.handshake.role is 'teacher'
    User.signIn sid

  socket.on 'sync', (service,data,cb)->
    data.options ?= {}
    _.extend data.options, {
      user: socket.handshake.user
      userId: socket.handshake.userId
      role: socket.handshake.role
    }
    services[service].sync data, cb
    console.log 'sync recvd: ', util.inspect data

  socket.on 'auth', (data, cb)->
    studentAuth.signin data, cb

  socket.on 'disconnect', (x,y,z)->
    delete connectedSockets[sid = socket.handshake.userId]
    if socket.handshake.role is 'student'
      Student.signOut sid
    if socket.handshake.role is 'teacher'
      User.signOut sid



# when a teacher's piggyBank changes (because of an student transfer or purchase), send a notice to that user
User.on 'change:piggyBank', (user)->
  connectedSockets[user._id]?.emit 'sync','user', { method: 'piggyBank', model: user }

# when a student comes on/offline, notify the teacher
Student.on 'change:online', (student)->
  connectedSockets[student.teacherId]?.emit 'sync', 'student', { method: 'online', model: student }




tasks = [
  { freq: 5000, func: require './tasks/cacheTwitterFollowers' }
]
  
doEvery = (someTime,action)->
  setInterval action, someTime

for task in tasks
  {freq,func} = task
  doEvery freq, func



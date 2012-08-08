
_ = require 'underscore'

# access to the api via socket connection

io = require 'socket.io'
red = require('redis').createClient()

sio = io.listen 8080

# data classes used to create api services
Student = require './db/student'
File = require './db/file'
User = require './db/user'


sio.configure ->
  sio.set 'authorization', (hs,cb)->

    if hs.headers.host is 'localhost'
      cb null,true
    else

      # make sure the user is logged in before accepting a connection
      # look for the sessionId cookie

      cookieStr = _.find hs.headers.cookie?.split(';'), (i)-> /sessionId/.test(i)
      
      ssid = (unescape cookieStr?.split('=')[1])

      # find the session in redis
      red.get "sess:#{ssid}", (err, sessStr)->
        console.log sessStr
        sess = JSON.parse sessStr
        hs.sess = sess
        hs.userId = sess.auth?.userId
        if sess.auth?.twitter then hs.role = 'teacher'
        
        # get the user
        User.findById hs.userId, (err,user)->
          hs.user = user or err
          if hs.user then cb null, true
          else cb 'unauthorized', false


services =
  student: Student
  file: File
  user: User


sio.on 'connection', (socket)->

  # pass any incoming sync request to the data class for handling
  # each service must have a .sync method

  socket.on 'sync', (service,data,cb)->
    data.options ?= {}
    _.extend data.options, {
      user: socket.handshake.user
      userId: socket.handshake.userId
      role: socket.handshake.role
    }
    services[service].sync data, cb



tasks = [
  { freq: 5000, func: require './tasks/cacheTwitterFollowers' }
]
  
doEvery = (someTime,action)->
  setInterval action, someTime

for task in tasks
  {freq,func} = task
  doEvery freq, func



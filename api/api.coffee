
io = require 'socket.io'

sio = io.listen 8080

Student = require './db/student'

services =
  student: Student

sio.on 'connection', (socket)->

  socket.on 'sync', (service,data,cb)->
    services[service].sync data, cb

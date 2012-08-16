CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
User = require '../db/user'
Student = require '../db/student'
_ = require 'underscore'
util = require 'util'

red = require('redis').createClient()


class Lab

  @bringStudent: (sio,student)->
    User.findById student.teacherId, (err,user)=>
      stuClients = sio.sockets.clients("self:#{student._id}")
      for stu in stuClients
        stu.join "lab:#{student.teacherId}"
        stu.emit 'sync', 'lab', { method: 'join', model: user.labState }

  @sync: (data,cb)->

    {method,model,options} = data

    {userId,role,sio,socket} = options

    switch method

      when 'read:students'
        if (role is 'teacher')
          cb null, _.pluck sio.sockets.clients("lab:#{userId}"), 'id'

      when 'update:state'
        if (role is 'teacher')
          sio.sockets.in("lab:#{userId}").emit 'sync', 'lab', { method: 'update:state', model: model }
          User.update { _id: userId }, { $set: { labState: model } }, false, false
          cb null, model

      when 'add:student'
        if not _.isArray options.studentIds then options.studentIds = [options.studentIds]
        Student.startControl options.studentIds


      when 'remove:student'
        if not _.isArray options.studentIds then options.studentIds = [options.studentIds]
        Student.stopControl options.studentIds
        


module.exports = Lab
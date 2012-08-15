CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
User = require './user'
Student = require './student'
_ = require 'underscore'
util = require 'util'

red = require('redis').createClient()

mongoose.connect "mongoose://localhost/lingualab"


LabSchema = new Schema {
  created: {type: Date, default: Date.now()}
  modified: {type: Date, default: Date.now()}
  teacherId: {type: ObjectId, ref: User}
}


LabSchema.statics =
  
  sync: (data,cb)->

    {method,model,options} = data

    {userId,role,sio,socket} = options

    switch method

      when 'read'
        if role is 'teacher'
          @find { teacherId: userId }, cb

      when 'create'
        if role in ['teacher','admin']

          lab = new @ model
          lab.teacherId = userId

          lab.save (err)=>
            cb err, lab


      when 'startSession'
        if (role is 'teacher') and (model.teacherId is userId)
          socket.join "teacher:lab:#{model.teacherId}"
          cb null, model._id
        else if student
          socket.join "student:lab:#{userId}"
          cb null, model._id

      when 'stopSession'
        if (role is 'teacher') and (model.teacherId is userId)
          socket.leave "teacher:lab:#{model._id}"
        else if student
          socket.leave "student:lab:#{userId}"

      when 'update:state'
        if (role is 'teacher')
          for stu in sio.sockets.clients("teacher:lab:#{model.teacherId}")
            stu.get 'userId', (err,uid)-> 
              console.log "sending update to #{uid}"
          sio.sockets.in("teacher:lab:#{model.teacherId}").emit 'sync', 'lab', { method: 'update:state', model: model }
          cb null, model

      when 'add:student'
        if not _.isArray options.studentIds then options.studentIds = [options.studentIds]
        if (role is 'teacher') and (model.teacherId is userId)
          
          # put student in control mode
          # TODO: make sure this gets cleared on teacher logout
          Student.startControl options.studentIds
          for studentId in options.studentIds

            
            
            

            # if the student is online, pull into the lab now
            stu = sio.getSockFor studentId
            #sck?.get 'userId', (err,uid)->
            #  console.log "client in self:#{studentId} : #{ uid }"
            stu?.join "teacher:lab:#{model.teacherId}"
            stu?.emit 'sync', 'lab', { method: 'join', model: lab }

            cb null, model.state


          


module.exports = mongoose.model 'lab', LabSchema
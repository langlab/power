#CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
User = require './user'
_ = require 'underscore'

Password = require '../lib/password'
sendMail = require '../lib/sendMail'

mongoose.connect "mongoose://localhost/lingualab"

StudentSchema = new Schema {
  created: {type: Date, default: Date.now()}
  modified: {type: Date, default: Date.now()}
  teacherId: {type: ObjectId, ref: User}
  email: { type: String,  validate: [/^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/, 'email address is invalid']}
  password: { type: String, validate: [/[^ ]{6,20}/,'password must be at least 6 characters'] }
  name: { type: String, validate: [/[a-zA-Z']+/, 'name'] }
  piggyBank: { type: Number, default: 0 }
}

StudentSchema.methods =

  sendEmail: (options, cb)->
    _.extend options, {
      to: @email
    }

    sendMail options, cb

StudentSchema.statics =

  generatePassword: (howMany,cb)->
    console.log 'gp reached',howMany,cb
    pw = new Password
    pw.seed ->
      cb pw.generate(howMany)

  changePennies: (id, byAmount, cb)->
    @findById id, (err,student)=>
      if err then cb err, null
      else
        User.changePennies student.teacherId, (0 - byAmount), (err)=>
          if not err
            student.piggyBank += byAmount
            student.save (err)->
              cb err, student

  sync: (data,cb)->
    {method, model, options} = data
    #console.log 'student sync reached', method, model, options
    switch method
      
      when 'read'

        if (id = model?._id ? options?.id)
          @findById id, (err,student)=>
            student.populate 'teacherId'
            cb err, student
        else
          if options.role is 'admin'
            @find {}, (err,students)=>
              cb err, students

          if options.role is 'teacher'
            @find {teacherId: options.userId}, (err,students)=>
              console.log 'students for teacher: ',students
              cb err, students

      when 'create'
        if options.role in ['teacher','admin']

          student = new @ model

          student.teacherId = options.userId
          
          @generatePassword 1, (pw)->
            student.password = pw

            student.save (err)=>
              #if not err then @emit 'sync', {method: 'create', model: student}
              console.log 'create: ',err,student
              cb err, student

      when 'update'
        {_id: id} = model
        delete model._id

        update = (cb)=>
          @findById id, (err,student)->
            delete model.piggyBank
            _.extend student, model
            student.modified = Date.now()
            student.save (err)=>
              cb err, student

        if model.password is '*' and options.regenerate is true
          @generatePassword 1, (pw)->
            model.password = pw
            update cb
        else
          update cb


      when 'delete'
        {_id: id} = model
        @findById id, (err, student)->
          if err then cb err
          else if student
            if student.piggyBank
              User.changePennies student.teacherId, student.piggyBank, (err)->
                if not err then student.remove (err)->
                  cb err, id

      when 'email'
        console.log 'trying to email.'
        {_id: id} = model
        {subject,body} = options
        @findById id, (err,student)->
          if err then cb err
          else if student
            student.sendEmail options, cb

      when 'changePennies'
        console.log 'changing pennies'
        {_id:id} = model
        {byAmount} = options
        @changePennies id, byAmount, cb

      when 'changePasswords'
        {ids,role} = options
        if role in ['teacher','admin']

          cbMomma = _.after ids.length, (err,students)->
            cb err, students

          console.log ids
          @generatePassword ids.length, (pws)=>
            @find { _id: { $in: ids } }, (err,students)->
              console.log students.length,' found'
              for stu,i in students
                stu.password = pws[i]
                stu.save (err)->
                  console.log 'saved: ',stu._id
                  cbMomma err, students



  findByEmail: (email, cb)->
    @findOne { email: email}, cb


module.exports = mongoose.model 'student',StudentSchema
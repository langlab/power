CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
User = require './user'
_ = require 'underscore'
gpw = require('../lib/gpw').generate

Password = require '../lib/password'
sendMail = require '../lib/sendMail'

red = require('redis').createClient()

mongoose.connect "mongoose://localhost/lingualab"

StudentSchema = new Schema {
  created: {type: Date, default: Date.now()}
  modified: {type: Date, default: Date.now()}
  teacherId: {type: ObjectId, ref: User}
  email: { type: String,  validate: [/^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/, 'email address is invalid']}
  password: { type: String, validate: [/[^ ]{6,20}/,'password must be at least 6 characters'] }
  name: { type: String, validate: [/[a-zA-Z']+/, 'name'] }
  piggyBank: { type: Number, default: 0 }
  online: { type: Boolean, default: false }
  control: { type: Boolean, default: false }
  teacherName: String
}

StudentSchema.methods =

  sendEmail: (options, cb)->
    _.extend options, {
      to: @email
    }

    sendMail options, cb

StudentSchema.statics =

  setOnline: (id,cb)->
    @findById id, (err,student)=>
      if student 
        student.online = true
        student.save (err)->
          if cb then cb err, student
          @emit 'change:online', student
  
  setOffline: (id)->
    if id is 'all'
      console.log 'signing out all students'
      @update { online: true }, { $set: { online: false } }, false, true
    else
      @findById id, (err, student)=>  
        if student 
          student.online = false
          student.save()
          @emit 'change:online', student

  startControl: (ids)->
    console.log 'controlling ',ids
    if not _.isArray ids then ids = [ids]
    for id in ids
      @findById id, (err, student)=>
        if student
          student.control = true
          student.save()

  stopControl: (ids)->
    if not _.isArray ids then ids = [ids]
    for id in ids
      @findById id, (err, student)=>
        if student
          student.control = false
          student.save()

  stopTeacherControl: (teacherId)->
    @update { teacherId: teacherId }, { $set: { control: false } }, false, true
  

  getLoginKeyFor: (student, secondsValid)->

    key = gpw(3) + Math.floor(Math.random()*10) + '' + Math.floor(Math.random()*10) + gpw(3)
    student.password = null
    student.role = 'student'
    red.set "lingualabio:studentAuth:#{key}", JSON.stringify student
    red.expire "lingualabio:studentAuth:#{key}", secondsValid
    key

  authEmailPass: (email, password, cb)->
    Student.find { email: email }, (err, students)->
      if not students.length then cb { type: 'email', message: 'That email address could not be found' }, null
      else if not password 
        cb null, students
      else
        match = _.find students, (stu)-> stu.password is password
        if match then cb null, match
        else cb { type: 'password', message: 'Incorrect password' }, null


  generatePassword: (howMany,cb)->
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
            student.save (err)=>
              cb err, student
              @emit 'change:piggyBank', student



  sync: (data,cb)->
    {method, model, options} = data
    #console.log 'student sync reached', method, model, options
    switch method
      
      when 'read'

        if (id = model?._id ? options?.id)
          @findById id, (err,student)=>
            #student.populate 'teacherId'
            User.findById student.teacherId, (err,user)=>
              student.teacherName = user.teacherName
              cb err, student
        else
          if options.role is 'admin'
            @find {}, (err,students)=>
              cb err, students

          if options.role is 'teacher'
            @find {teacherId: options.userId}, (err,students)=>
              cb err, students

      when 'create'
        if options.role in ['teacher','admin']

          student = new @ model

          student.teacherId = options.userId
          
          @generatePassword 1, (pw)->
            student.password = pw

            student.save (err)=>
              #if not err then @emit 'sync', {method: 'create', model: student}
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
        id = model?._id

        {subject,html,ids,role} = options


        if not ids then ids = [id?] ? []

        if role in ['teacher','admin']

          @find { _id: { $in: ids } }, (err,students)=>
            
            if err then cb err
            else if students
              for student in students
                template = html

                for fld in ['name','email','password']
                  template = template.replace "{#{fld}}", student[fld]
                
                if /{signin-link}/.test template
                  template = template.replace "{signin-link}", "http://#{CFG.HOST()}/studentAuth/#{@getLoginKeyFor student, 600}"
                
                options.html = template
                student.sendEmail options, cb

      when 'getLoginKey'

        {_id:studentId} = model
        {role, secondsValid} = options

        if role in ['teacher','admin']

          @findById studentId, (err,student)=>
            cb err, @getLoginKeyFor student, secondsValid ? 60

      when 'changePennies'
        {_id:id} = model
        {byAmount} = options
        @changePennies id, byAmount, cb

      when 'changePasswords'
        {ids,role} = options
        if role in ['teacher','admin']

          cbMomma = _.after ids.length, (err,students)->
            cb err, students

          @generatePassword ids.length, (pws)=>
            @find { _id: { $in: ids } }, (err,students)->
              for stu,i in students
                stu.password = pws[i]
                stu.save (err)->
                  cbMomma err, students



  findByEmail: (email, cb)->
    @findOne { email: email}, cb


module.exports = mongoose.model 'student',StudentSchema


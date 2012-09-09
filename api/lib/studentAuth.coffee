_ = require 'underscore'
gpw = require('../lib/gpw').generate
red = require('redis').createClient()
util = require 'util'

sendMail = require './sendMail'

Student = require '../db/student'
User = require '../db/user'

#console.log util.inspect Student

shortKey = ->
  gpw(3) + Math.floor(Math.random()*10) + '' + Math.floor(Math.random()*10) + gpw(3)

getLoginKeyFor = (studentInfo, secondsValid, cb)->
  key = shortKey()
  Student.findById studentInfo._id, (err,student)->
    #console.log 'teacherId: ',student.teacherId
    User.findById student.teacherId, (err,user)->
      #console.log 'teacher: ',user
      student.teacherName = user.twitterName
      student.password = null
      student.role = 'student'
      red.set "lingualabio:studentAuth:#{key}", JSON.stringify student
      red.expire "lingualabio:studentAuth:#{key}", secondsValid
      cb key

authEmailPass = (email, password, teacherId, cb)->
  console.log email, password, teacherId
  Student.findByEmailAndTeacher email, teacherId, (err, student)->
    console.log err,student
    if not student then cb { type: 'email', message: 'That email address could not be found' }, null
    else if not password 
      cb null, student
    else
      if student.password is password then cb null, student
      else cb { type: 'password', message: 'Incorrect password' }, null

signin = (options,cb)->
  
  console.log options

  _.defaults options, {
    secondsValid: if options.forgot then 600 else 45
  }

  { email, password, secondsValid, forgot, teacherId } = options

  #console.log 'forgot: ',forgot
  if forgot in [true,'true']
    
    authEmailPass email, '', teacherId, (err, student)->
      console.log student._id, student.teacherId
      if (not student) or err
        cb { type: 'email', message: 'That email address could not be found' }, null
      else
        User.findById student.teacherId, (err,user)=>
          message = """
          <h2> Hi, #{student.name}! </h2>
          <p>
          I understand you forgot your password. No problem!

          Your password is #{student.password}
          Please return to <a href='https://langlab.org/#{user.twitterUser}'>#{user.teacherName}'s login page</a> to sign in.
          
          Cheers.
          </p>
          """

          options =
            to: email
            subject: 'Help signing in'
            html: message

          sendMail options, cb
        

  else
    authEmailPass email, password, teacherId, (err, student)->
      if err then cb err
      else
        #console.log 'student found:',student
        getLoginKeyFor student, secondsValid, (key)->
          cb err, (if student then key else null)
      

module.exports =
  authEmailPass: authEmailPass
  getLoginKeyFor: getLoginKeyFor
  signin: signin
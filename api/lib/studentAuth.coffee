_ = require 'underscore'
gpw = require('../lib/gpw').generate
red = require('redis').createClient()

sendMail = require './sendMail'

Student = require '../db/student'

shortKey = ->
  gpw(3) + Math.floor(Math.random()*10) + '' + Math.floor(Math.random()*10) + gpw(3)

getLoginKeyFor = (student, secondsValid)->
  key = shortKey()
  student.password = null
  student.role = 'student'
  red.set "lingualabio:studentAuth:#{key}", JSON.stringify student
  red.expire "lingualabio:studentAuth:#{key}", secondsValid
  key

authEmailPass = (email, password, cb)->
  Student.find { email: email }, (err, students)->
    if not students.length then cb { type: 'email', message: 'That email address could not be found' }, null
    else if not password 
      cb null, students
    else
      match = _.find students, (stu)-> stu.password is password
      if match then cb null, match
      else cb { type: 'password', message: 'Incorrect password' }, null

signin = (options,cb)->
  
  console.log options

  _.defaults options, {
    secondsValid: if options.forgot then 600 else 45
  }

  { email, password, secondsValid, forgot } = options

  console.log 'forgot: ',forgot
  if forgot in [true,'true']
    
    authEmailPass email, '', (err, students)->
      console.log students
      if (not students) or err
        cb { type: 'email', message: 'That email address could not be found' }, null
      else
        message = """
        <pre>
        <h2> Hi, #{students[0].firstName}! </h2>

        I understand you forgot your password. No problem!

        """
        if students.length > 1
          message += """
            You have #{students.length} different accounts:
          """ 
        for student in students
          key = getLoginKeyFor student, secondsValid
          console.log key
          message += """
          The password is #{student.password}
          Just <a href='http://lingualab.io/studentAuth/#{key}'>click here to login.</a><br/>
          This link will expire 10 minutes after you receive this email.

          Cheers.
        </pre>
          """

        options =
          to: email
          subject: 'Help signing in to lingualab'
          html: message

        sendMail options, cb
        

  else
    authEmailPass email, password, (err, student)->
      console.log 'student found:',student
      cb err, (if student then (getLoginKeyFor student, secondsValid) else null)
      

module.exports =
  authEmailPass: authEmailPass
  getLoginKeyFor: getLoginKeyFor
  signin: signin
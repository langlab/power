CFG = require '../conf'
util = require 'util'
red = require('redis').createClient()

# is the user 'following' lingualab.io on twitter?
isValidTwitterId = (id,cb)->
  red.get CFG.TWITTER.FOLLOWER_CACHE_KEY, (err,followers)->
    cb (id in JSON.parse followers)

module.exports = (app)->

  app.get '/', (req,res)->

    console.log 'user: ',util.inspect req.user
    console.log 'session: ', util.inspect req.session.id

    if req.user?.role is 'teacher'

      # set a cookie to validate socket connection
      res.cookie('sessionId',req.session.id,{domain:'.lingualab.io'})
      
      isValidTwitterId req.session.auth.twitter.user.id, (valid)->
        if valid
          res.render 'teacher', {session: req.session, user: req.user, CFG: CFG, files: files?}
        else res.render 'twitter', {session: req.session, CFG: CFG}
      
    else if req.session?.role is 'student'
      res.cookie('sessionId',req.session.id,{domain:'.lingualab.io'})

      res.render 'student', { session: req.session, CFG: CFG, user: req.session.user }


    else
      res.render 'welcome', {session: req.session, CFG: CFG}
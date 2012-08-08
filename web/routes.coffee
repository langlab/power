CFG = require '../conf'
util = require 'util'
red = require('redis').createClient()

# is the user 'following' lingualab.io on twitter?
isValidTwitterId = (id,cb)->
  red.get CFG.TWITTER.FOLLOWER_CACHE_KEY, (err,followers)->
    cb (id in JSON.parse followers)

bootstrap = (req)-> 
  clientData = 
        session: 
          id: req.session.id
          expires: req.session.cookie.expires
          lastAccess: req.session.lastAccess
          data: req.session
          user: req.user
        CFG: CFG.CLIENT()

  """
        <script id='sessionBootstrap'>
          window.data = #{JSON.stringify clientData};
          window.sock = window.io.connect('http://api.lingualab.io');
          setTimeout(function() { $('#sessionBootstrap').remove(); }, 500 );
        </script>
  """

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
      
    else
      res.render 'welcome', { bootstrap: bootstrap(req) }


  app.get '/studentAuth/:key', (req,res)->
    {key} = req.params

    red.get "lingualabio:studentAuth:#{key}", (err, student)->
      if student
        req.session.user = JSON.parse student
        req.session.role = 'student'
      res.redirect '/'


  app.get '/studentLogout', (req,res)-> 
    req.session.destroy()
    res.redirect '/'


  app.get '/:teacher', (req,res)->
    if req.session?.user and req.session?.role is 'student'
      res.cookie 'sessionId', req.session.id {domain:'.lingualab.io'}
      res.render 'student', { bootstrap: bootstrap(req) }
    else
      res.render 'login', { bootstrap: bootstrap(req), teacherTwitter: req.params.teacher }
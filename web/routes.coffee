CFG = require '../conf'
util = require 'util'
red = require('redis').createClient()
util = require 'util'

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
      student: req.session.student
    CFG: CFG.CLIENT()

  """
        <script id='sessionBootstrap'>
          window.data = #{JSON.stringify clientData};
          setTimeout(function() { $('#sessionBootstrap').remove(); }, 500 );
        </script>
  """

module.exports = (app)->


  app.get '/s', (req,res)->
    res.json req.session

  app.get '/', (req,res)->

    #console.log 'user: ',util.inspect req.user
    #console.log 'session: ', util.inspect req.session.id

    if req.user?.role is 'teacher'

      # set a cookie to validate socket connection
      res.cookie('sessionId',req.session.id,{domain:'.langlab.org'})
      
      isValidTwitterId req.session.auth.twitter.user.id, (valid)->
        if valid
          res.render 'teacher', { bootstrap: bootstrap(req) }
        else res.render 'twitter', { bootstrap: bootstrap(req) }
      
    else
      res.render 'welcome', { bootstrap: bootstrap(req) }


  app.get '/studentAuth/:key', (req,res)->
    {key} = req.params
    # set a cookie to validate socket connection
    res.cookie('sessionId',req.session.id,{domain:'.langlab.org'})
    red.get "lingualabio:studentAuth:#{key}", (err, student)->
      if student
        req.session.student = JSON.parse student
        res.redirect "/#{req.session.student.teacherId}"
      else
        res.send 'This link is invalid or expired.'



  app.get '/studentLogout', (req,res)-> 
    delete req.session.student
    res.redirect "/geodyer"


  app.get '/:teacher', (req,res)->
    res.cookie 'sessionId', req.session.id, {domain:'.langlab.org'}
    if req.session?.student
      res.render 'student', { bootstrap: bootstrap(req) }
    else
      res.render 'login', { bootstrap: bootstrap(req), teacherTwitter: req.params.teacher }
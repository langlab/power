CFG = require '../conf.coffee'
express = require 'express'
everyauth = require 'everyauth'
coffeefilter = require '../node_modules/coffeefilter/src/coffeefilter'
util = require 'util'

User = require '../api/db/user'

RedisStore = require('connect-redis')(express)
store = new RedisStore()
redis = require 'redis'
red = redis.createClient()

# important because MongoDB uses _id as the primary key
#console.log everyauth.everymodule

everyauth.everymodule.userPkey '_id'

everyauth.everymodule.findUserById (userId, cb)->
  console.log 'userId: ',userId
  User.findById userId, cb



everyauth.twitter
  .consumerKey(CFG.TWITTER.CONSUMER_KEY)
  .consumerSecret(CFG.TWITTER.CONSUMER_SECRET)
  .callbackPath('/twitter/callback')
  .findOrCreateUser( (session, accessToken, accessTokenSecret, twitterData)->
    
    promise = @Promise()

    User.auth twitterData, (err,resp)->
      console.log util.inspect resp
      if err
        promise.fail err
        return
      else
        console.log 'fulfilling promise'
        promise.fulfill resp

    return promise

  ).redirectPath('/')


app = express()

app.configure ->
  
  app.use express.cookieParser()
  app.use express.session {
    secret: 'keyboardCat'
    key: 'express.sid'
    cookie: { domain: '.lingualab.io' }
    store: store
  }
  app.use everyauth.middleware()
  app.use express.bodyParser()
  app.use express.static "./pub"
  app.use express.methodOverride()
  app.use express.errorHandler()
  app.set 'views', "./templates"
  app.set 'view options', { layout: false }
  app.set 'view engine', 'coffee'
  app.engine '.coffee', coffeefilter.adapters.express


# add routes to app
require('./routes')(app)



app.listen 8181
###
# server-side application configuration data
###

module.exports =

  INFO:
    NAME: 'lingualab'
    AUTHOR: 'George Pezzuti Dyer'
    URL: 'http://github.com/georgedyer'

  STAGE: 'DEV'  # 'DEV' or 'PROD'
 
  DEV_HOST: 'lingualab.io'
  PROD_HOST: 'lingualab.io'

  HOST: -> @["#{ @STAGE }_HOST"]

  DEV_PORT: 8181
  PROD_PORT: 8181

  PORT: -> @["#{ @STAGE }_PORT"]

  TWITTER:
    CONSUMER_KEY: 'aoMCcJR62q9GYRAP9OOUQ'
    CONSUMER_SECRET: 'oT133ULqySY3H55xWQHa7nA5iV7a1UzAFJMnubyw'
    ACCOUNT_NAME: 'lingualabio'
    FOLLOWER_CACHE_KEY: 'lingualabio:followers'

  S3:
    KEY: 'AKIAIUJTVW7ZLSILOJRA'
    SECRET: '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'
    MEDIA_BUCKET: 'lingualabio-media'
    URL_ROOT: 'https://s3.amazonaws.com/'

  ZENCODER:
    API_KEY: 'f5c83bc0ed512a395cb1dff562d6583c'
    API_HOST: "app.zencoder.com"
    API_PATH: "/api/v2/jobs"

  DB:
    HOST: 'http://localhost'
    NAME: 'lingualab'
    PORT: 27017

  SIO:
    HOST: 'localhost:8080'

  API:
    HOST: 'localhost'
    PORT: 8080

  # have CLIENT return the configuration object to inject into the client
  CLIENT: ->

    CLIENT_DATA =
      INFO: @INFO




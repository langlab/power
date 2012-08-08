CFG = require "../../conf"
red = require('redis').createClient()
http = require 'http'


module.exports = ->
  #console.log 'running twitter followers cache'
  red.get CFG.TWITTER.FOLLOWER_CACHE_KEY, (err,prev)->
    #console.log "prev followers: #{prev}"
  
  options =
    host: "api.twitter.com"
    path: "/1/followers/ids.json?screen_name=#{CFG.TWITTER.ACCOUNT_NAME}"
    headers:
      'Accept': 'text/json'
      'Content-type': 'text/plain'

  http.get options, (resp)->
    resp.setEncoding 'utf8'
    data = ''
    
    resp.on 'data', (chunk)->
      data += chunk

    resp.on 'end', ->
      

      {ids} = JSON.parse data
      #console.log 'current followers: ', ids
      if ids? then red.set "lingualabio:followers", JSON.stringify ids 


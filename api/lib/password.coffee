fs = require 'fs'
red = require('redis').createClient()
_ = require 'underscore'


class Password
  
  loadDB: ->

    words = (fs.readFileSync '/usr/share/dict/words', 'utf8')
    words += (fs.readFileSync '/usr/share/dict/connectives', 'utf8')
    words = words.split '\n'
    words = (word for word in words when 3 < word.length < 7)

    red.set 'lingualab:pwords-en', words.join ','


  loadWords: (cb)->

    red.get 'lingualab:pwords-en', (err,resp)=>
      #console.log 'redis pwords: ',err,resp
      if (not resp) or err then cb err
      else 
        @words = resp.split ','
        cb()

  seed: (cb)->
    @loadWords (err)=>
      if (not @words) or err
        @loadDB()
        @loadWords (err)->
          cb()
      else
        cb()

  generate: (howmany = 1)->

    passwords = []

    for i in [1..howmany]

      rand1 = Math.floor (Math.random() * @words.length)

      a = @words[rand1].toLowerCase()


      words2 = _.filter @words, (w) -> w.length < (8-a.length)

      #console.log 'words2: ',words2.join ','

      rand2 = Math.floor (Math.random() * words2.length)

      d = words2[rand2].toLowerCase()

      b = Math.floor(Math.random()*9) + 1
      c = Math.floor(Math.random()*10)

      passwords.push a + b + c + d

    if howmany is 1 then passwords[0] else passwords



  


module.exports = Password


express = require 'express'

app = express()

app.get '/', (req,res)->
  res.redirect 'https://langlab.org'


app.listen 7766


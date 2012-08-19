express = require 'express'

app = express()

app.get '/', (req,res)->
  res.end '• Patience, grasshopper.'


app.listen 7766


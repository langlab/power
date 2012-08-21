formid = require 'formidable'
http = require 'http'
util = require 'util'

serv = http.createServer (req,res)->
  if req.url is '/upload' and req.method.toLowerCase() is 'post'
    form = new formid.IncomingForm()
    form.parse req, (err, fields, files)->
      res.writeHead(200, {'content-type': 'text/plain'})
      res.write('received upload:\n\n')
      res.end(util.inspect({fields: fields, files: files}))
      console.log util.inspect({fields: fields, files: files})

serv.listen 8080
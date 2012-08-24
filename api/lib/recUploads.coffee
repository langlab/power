formid = require 'formidable'
http = require 'http'
util = require 'util'
qs = require 'querystring'

url = require 'url'
fs = require 'fs'


serv = http.createServer (req,res)->
  
  {pathname,query} = url.parse req.url 
  queryObj = qs.parse query
  
  if pathname is '/rec' and req.method.toLowerCase() is 'get'
    {ref} = queryObj
    
    fs.readFile "/tmp/#{queryObj.ref}", (err,data)=>
      
      if err
        res.writeHead(404)
        res.end JSON.stringify(err)
      
      res.writeHead 200
      res.end data


  if pathname is '/rec' and req.method.toLowerCase() is 'post'
    
    form = new formid.IncomingForm()
    
    form.parse req, (err, fields, files)->
      
      {filename,path,lastModifiedDate,size} = files.file
      {data} = queryObj
      dataObj = JSON.parse (new Buffer(data, 'base64')).toString()
      {t,s,ts,tags} = dataObj

      ref = path.split('/')[2]

      serv.emit 'rec:upload', {
        ref: ref
        size: size
        teacherId: t
        studentId: s
        request: ts
        tags: tags
      }
      
      res.writeHead(200, {'content-type': 'application/json'})
      res.end(JSON.stringify({fields: fields, files: files}))
      #console.log util.inspect({fields: fields, files: files})



module.exports = serv
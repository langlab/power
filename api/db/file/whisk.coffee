
CFG = require '../../../conf'

request = require 'request'
https = require 'https'

knox = require 'knox'
url = require 'url'

{EventEmitter} = require 'events'


class Whisk extends EventEmitter

  constructor: (@sourceUrl, @s3fileName)->

    @source = url.parse sourceUrl

    @knox = knox.createClient {
      key: CFG.S3.KEY
      secret: CFG.S3.SECRET
      bucket: CFG.S3.MEDIA_BUCKET
    }

  pipeToS3: (cb)->

    request.get @sourceUrl, { encoding: null }, (err, res, body)=>
      
      console.log res?.statusCode
      kn = @knox.put @s3fileName, {
        'Content-Type': res.headers['content-type']
        'Content-Length': res.headers['content-length']
      }, (err,resp)=>

      kn.on 'response', cb

      kn.on 'error', cb

      kn.end(body)



module.exports = Whisk


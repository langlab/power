https = require 'https'
CFG = require '../../../conf'
{EventEmitter} = require 'events'
_ = require 'underscore'

ffmpeg = require 'fluent-ffmpeg'

util = require 'util'


wait = (someTime,thenDo) ->
  setTimeout thenDo, someTime
doEvery = (someTime,action)->
  setInterval action, someTime



class Encoder extends EventEmitter

  outputs:
    video: ['webm','mp4']
    audio: ['mp3','ogg']

  constructor: (@file)->

  download: (cb)->
    tempPath = "/tmp/#{@file._id}_#{@file.filename}"
    request @file.fpUrl, (err,resp,body)=>
      fs.writeFile tempPath, body, (err)=>
        cb err, tempPath

  screenshot: (cb)->
    ss = exec "ffmpeg -i /tmp/#{@file._id}_#{@file.filename} -ss 00:00:03 -f image2 -vframes 1 /tmp/#{@file._id}.png"
    #ss.stdout.on 'data', (data)-> console.log data.toString()
    #ss.stderr.on 'data', (data)-> console.log data.toString()
    ss.on 'exit', (code)=>
      knox.putFile "/tmp/#{@file._id}.png", "/#{@file._id}.png", (err,resp)=>
        @file.thumbUrl = "https://s3.amazonaws.com/lingualabio-media/#{@file._id}.png"
        @file.save (err)=>
          @emit 'screenshot', @file
          cb err, "/#{@file._id}.png"

  duration: (ext)->
    metadata = exec "ffmpeg -i /tmp/#{@file._id}.#{ext}"
    dataStr = ""
    metadata.stdout.on 'data', (data)->
      dataStr += data.toString()
    metadata.stderr.on 'data', (data)->
      dataStr += data.toString()
    metadata.on 'exit', =>
      console.log dataStr
      dur = dataStr.match(/Duration: [0-9]{2}:([0-9]{2}):([0-9]{2}\.?[0-9]*),/)
      @file.duration = Math.floor((parseInt(dur[1],10)*60 + parseFloat(dur[2]))*1000)
      @file.save()

  encodeExt: (ext,cb)->

    enc = new ffmpeg { source: "/tmp/#{@file._id}_#{@file.filename}", timeout: 300 }

    enc.saveToFile "/tmp/#{@file._id}.#{ext}", (retcode,err)=>
      #console.log "encoded #{@file._id}.#{ext}"
      
      knox.putFile "/tmp/#{@file._id}.#{ext}", "/#{@file._id}.#{ext}", (err,resp)=>

        #console.log err ? "uploaded: #{@file._id}.#{ext}"
        cb err ? 'done'

    enc.onProgress (progress)=>
      console.log "prog:",util.inspect progress
      @emit 'progress', progress.percent, ext

  
  encode: -> 
    @download =>
      extensions = @outputs[@file.type]
      for ext,i in extensions
        @encodeExt ext, (resp)=>
          if i is 0 then @duration ext
      
      @screenshot =>
        


class Zencoder extends EventEmitter

  constructor: (@file)->
    @prepareJobReq()

  prepareJobReq: ->
    
    if @file.type is 'video'
      output = [
        {
          label: 'h264'
          format: 'mp4'
          video_codec: 'h264'
        }
        {
          label: 'webm'
          format: 'webm'
          video_codec: 'vp8'
        }
      ]
    else if @file.type is 'audio'
      console.log 'setting audio output'
      output = [
        {
          label: 'mp3'
          format: 'mp3'
        }
      ]


    output = _.filter output, (o)=>
  
      o.url = "s3://#{CFG.S3.MEDIA_BUCKET}/#{@file._id}.#{o.format}"
      o.public = 1
      
      if @file.type is 'video'
        o.thumbnails =
          number: 10
          base_url: "s3://#{CFG.S3.MEDIA_BUCKET}/"
          prefix: "#{@file._id}"
          size: "400x300"
          aspect_mode: 'pad'

      return o.format isnt @file.ext

    @jobReq = 
      input: "#{@file.fpUrl}"
      output: output

  startCheckingStatus: =>
    @statusChecker = doEvery 1000, @getJobStatus

  stopCheckingStatus: ->
    console.log 'stop checking status...'
    clearTimeout @statusChecker

  getJobDetails: =>
    options = 
      host: CFG.ZENCODER.API_HOST
      path: "/api/v2/jobs/#{@job.id}.json?api_key=#{CFG.ZENCODER.API_KEY}"
      headers:
        'Accepts':'application/json'

    info = ''
    https.get options, (resp)=>
      resp.setEncoding 'utf8'

      resp.on 'data', (data)=>
        info += data
        
      resp.on 'end', =>
        info = JSON.parse info
        @emit 'info', info.job

  getJobStatus: =>
    console.log 'getJobStatus called'
    options =
      host: CFG.ZENCODER.API_HOST
      path: "/api/v2/jobs/#{@job.id}/progress.json?api_key=#{CFG.ZENCODER.API_KEY}"
      headers:
        'Accepts':'application/json'


    https.get options, (resp)=>
      resp.setEncoding 'utf8'
      resp.on 'data', (data)=>
        progress = JSON.parse data
        @job.progress = progress
        eventType = if progress.state is 'finished' then 'finished' else 'progress'
        @emit eventType, @job
        if eventType is 'finished'
          @stopCheckingStatus()
          @getJobDetails()


  encode: (cb)->

    options =
      host: CFG.ZENCODER.API_HOST
      path: CFG.ZENCODER.API_PATH
      method: 'POST'
      headers:
        'Content-type':'application/json'
        'Content-length': JSON.stringify(@jobReq).length
        'Accept': 'application/json'
        'Zencoder-Api-Key': CFG.ZENCODER.API_KEY

    console.log 'requesting job: ',options, @jobReq
    jobCreate = https.request options, (resp)=>
      resp.setEncoding 'utf8'

      resp.on 'data', (@job)=>
        if _.isString(@job)
          @job = JSON.parse @job

        console.log 'from zen: ',@job

      resp.on 'end', =>
        console.log 'end req from zen'
        @startCheckingStatus()
        cb @job

    jobCreate.end JSON.stringify @jobReq, 'utf8'

module.exports = Zencoder


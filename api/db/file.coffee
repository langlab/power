CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
db = mongoose.createConnection 'localhost','lingualab'
moment = require 'moment'

_ = require 'underscore'
util = require 'util'
fs = require 'fs'

Student = require './student'
Whisk = require './file/whisk'
Zen = require './file/zen'

ffmpeg = require 'fluent-ffmpeg'

knox = require 'knox'

knox = knox.createClient {
  key: CFG.S3.KEY
  secret: CFG.S3.SECRET
  bucket: CFG.S3.MEDIA_BUCKET
}

FileSchema = new Schema {
  created: { type: Date, default: Date.now() }
  modified: { type: Date, default: Date.now() }
  fpUrl: String
  duration: Number
  thumbUrl: String
  prepProgress: { type: Number, default: 5 }
  owner: { type: ObjectId, ref: 'User' }
  student: { type: ObjectId, ref: 'Student' }
  title: { type: String, default: 'Untitled' }
  filename: String
  ext: String
  type: String
  mime: String
  size: Number
  status: String
  tags: String
  request: Number
  activity: { type: ObjectId, ref:'Activity' }
  recordings: {}
  feedBackFor: { type: ObjectId, ref: 'File' }
  feedback: [{}]
  height: Number
  width: Number
}

FileSchema.statics =
  
  whisk: (file, cb)->
    whisk = new Whisk file.fpUrl, "/#{file._id}.#{file.ext}"
    whisk.pipeToS3 (resp)=>
      if file.type in ['image','audio']
        file.status = 'finished'
        file.filename = file._id
      file.save (err)=>
        @emit 'change:progress', file
        cb err

  encode: (file)->
    zen = new Zen file
    zen.encode (job)->
      #console.log job

    zen.on 'info', (job)=>
      console.log 'info: ',job
      for output,i in job.output_media_files
        console.log "setting #{output.label} = #{output.url}"
        file["#{output.label}Url"] = output.url 
      file.duration = job.input_media_file.duration_in_ms
      file.status = 'finished'
      file.prepProgress = 100
      file.thumbUrl = "https://s3.amazonaws.com/lingualabio-media/#{file._id}_0004.png"
      file.filename = file._id
      file.save (err)=>
        @emit 'change:progress', file

    zen.on 'progress', (job)=>
      file.prepProgress = job.progress.progress
      for output,i in job.progress.outputs
        if output.state is 'finished'
          console.log "job outputs: #{job.outputs[i].label}Url"
          file["#{job.outputs[i].label}Url"] = job.outputs[i].url
      
      file.save (err)=>
        @emit 'change:progress', file

    zen.on 'finished', (job)=>
      #console.log 'finished: ', util.inspect job
      #@emit 'finished:processing', job

  recUpload: (fileData)->
    console.log 'reached File:', util.inspect fileData
    {ref,size,teacherId,studentId,request,title,tags,recordings} = fileData

    Student.findById studentId, (err,student)=>

      model =
        fpUrl: "http://up.langlab.org/rec?ref=#{ref}.mp3"
        size: size
        student: studentId
        owner: teacherId
        title: "#{title}: #{student.name}"
        type: 'audio'
        ext: 'spx'
        created: moment().valueOf()
        modified: moment().valueOf()
        request: request
        tags: tags
        recordings: recordings
        duration: _.reduce(_.pluck(recordings,'duration'), ( (memo,num)-> memo + num ), 0)

      file = new @ model
      file.save (err)=>
        @emit 'new', file
        #@encode file # --the old way with zencoder
        proc = new ffmpeg { source: "/tmp/#{ref}.spx" }
        proc.saveToFile "/tmp/#{ref}.mp3", (retcode,err)=>

          knox.putFile "/tmp/#{ref}.mp3", "/#{file._id}.mp3", (err,resp)=>
            file.status = 'finished'
            file.prepProgress = 100
            file.thumbUrl = '/img/cassette.svg'
            file.save (err)=>
              @emit 'change:progress', file
              fs.unlinkSync "/tmp/#{ref}.spx"
              fs.unlinkSync "/tmp/#{ref}.mp3"

  fbUpload: (fileData)->
    {ref,size,recordingId,insertAt,duration} = fileData
    @findById recordingId, (err,file)=>
      proc = new ffmpeg { source: "/tmp/#{ref}.spx" }
      proc.saveToFile "/tmp/#{ref}.mp3", (retcode,err)=>
        knox.putFile "/tmp/#{ref}.mp3", "/#{ref}.mp3", (err,resp)=>
          file.feedback.push {
            filename: ref
            insertAt: insertAt
            duration: duration
            size: size
            created: moment().valueOf()
          }
          file.save (err)=>
            @emit 'change:feedback', file
            fs.unlinkSync "/tmp/#{ref}.spx"
            fs.unlinkSync "/tmp/#{ref}.mp3"



  sync: (params,cb)->

    {method, model, options} = params

    switch method

      when 'read'

        if (id = model?._id ? options?.id)
          @find {_id: id}, (err,file)=>
            cb err, file
        else
          if options.role is 'admin'
            @find {}, (err,files)=>

          if options.role is 'teacher'
            @find {owner: options.userId}, (err,files)=>
              cb err, files


      when 'create'
        
        if options.role in ['teacher','admin']

          file = new @ model
          file.modified = moment().valueOf()
          file.created = moment().valueOf()

          file.owner = options.userId

          mtch = file.filename.match /(^.+)\.?([^\.]*)$/

          file.title = mtch?[1] or 'Untitled'
          file.ext = file.mime.split('/')[1].toLowerCase()

          file.save (err)=>
            file.filename = file._id
            cb err, file
            # post-processing
            switch file.type

              when 'image'
                @whisk file, =>
                  #console.log 'whisked: ',file
                  
              when 'video'
                switch file.ext
                  when 'webm','mp4','mov','m4v','flv'
                    @whisk file, =>
                      @encode file
                  else
                    @encode file

              when 'audio'
                switch file.ext
                  when 'mp3'
                    @whisk file, =>
                      file.status = 'finished'
                      file.thumbUrl = '/img/mp3.png'
                      file.filename = file._id
                      file.save (err)=>
                        @emit 'change:progress', file
                  else
                    @encode file


      when 'update'
        {_id: id} = model
        delete model._id
        model.modified = moment().valueOf()
        @findById id, (err,file)->
          _.extend file, model
          file.modified = moment().valueOf()
          console.log 'MOD: ',file.modified
          file.save (err)=>
            cb err, file
            
      when 'delete'
        {_id: id} = model
        @findById id, (err, file)=>
          {filename,ext,type} = file
          fn = filename
          file.remove (err)=>
            cb err, id
            @find { filename: fn }, (err,files)=>
              if not files?.length
                console.log 'deleting ',fn
                switch type
                  when 'image'
                    knox.deleteFile "/#{fn}.#{ext}", (err,res)=>
                  when 'video'
                    knox.deleteFile "/#{fn}.webm", (err,res)=>
                      console.log 'knox: ',err,res
                    knox.deleteFile "/#{fn}.mp4", (err,res)=>
                    for i in [0..9]
                      knox.deleteFile "/#{fn}_000#{i}.png", (err,res)=>

                  when 'audio'
                    knox.deleteFile "/#{fn}.mp3", (err,res)=>
                    knox.deleteFile "/#{fn}.ogg", (err,res)=>

                  else
                    knox.deleteFile "/#{fn}.#{ext}", (err,res)=>


module.exports = db.model 'file', FileSchema
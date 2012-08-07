{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
mongoose.connect "mongoose://localhost/lingualab"

_ = require 'underscore'
util = require 'util'

Whisk = require './file/whisk'
Zen = require './file/zen'

FileSchema = new Schema {
  created: { type: Date, default: Date.now() }
  modified: { type: Date, default: Date.now() }
  fpUrl: String
  imageUrl: String
  mp3Url: String
  h264Url: String
  webmUrl: String
  duration: Number
  thumbUrl: String
  prepProgress: Number
  owner: { type: ObjectId, ref: 'User' }
  title: { type: String, default: 'Untitled' }
  filename: String
  ext: String
  type: String
  mime: String
  size: Number
  status: String
  tags: String
}


FileSchema.statics =
  
  whisk: (file, cb)->
    whisk = new Whisk file.fpUrl, "/#{file._id}.#{file.ext}"
    whisk.pipeToS3 (resp)=>
      switch file.type
        when 'video'
          urlType = if file.ext in ['mp4','mov','m4v'] then "h264Url" else "webmUrl"
          file[urlType] = "https://s3.amazonaws.com/lingualabio-media/#{file._id}.#{file.ext}"
        when 'image'
          file.imageUrl = "https://s3.amazonaws.com/lingualabio-media/#{file._id}.#{file.ext}"
          file.status = 'finished'
        when 'audio'
          file.mp3Url = "https://s3.amazonaws.com/lingualabio-media/#{file._id}.#{file.ext}"
          file.status = 'finished'
      
      file.save (err)=>
        @emit 'sync', { method: 'update', model: file, options: { teacherId: file.owner } }
        cb err

  encode: (file)->
    zen = new Zen file
    zen.encode (job)->
      console.log job

    zen.on 'info', (job)=>

      file.duration = job.input_media_file.duration_in_ms
      file.status = 'finished'
      file.prepProgress = 100

      file.save (err)=>
        @emit 'sync', { method: 'update', model: file, options: { teacherId: file.owner } }

    zen.on 'progress', (job)=>
      file.prepProgress = job.progress.progress
      for output,i in job.progress.outputs
        if output.state is 'finished'
          console.log "#{job.outputs[i].label}Url"
          file["#{job.outputs[i].label}Url"] = job.outputs[i].url
          file.thumbUrl = "https://s3.amazonaws.com/lingualabio-media/#{file._id}_0004.png"
      file.save (err)=>
        @emit 'sync', { method: 'progress', model: file, options: { teacherId: file.owner } }

    zen.on 'finished', (job)=>
      console.log 'finished: ', util.inspect job
      #@emit 'finished:processing', job

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
              console.log err files

          if options.role is 'teacher'
            @find {owner: options.userId}, (err,files)=>
              console.log err,files
              cb err, files


      when 'create'
        
        if options.role in ['teacher','admin']

          file = new @ model

          file.owner = options.userId

          mtch = file.filename.match /(^.+)\.?([^\.]*)$/

          file.title = mtch?[1] or 'Untitled'
          file.ext = file.mime.split('/')[1].toLowerCase()

          file.save (err)=>
            cb err, file

            # post-processing
            switch file.type

              when 'image'
                @whisk file, =>
                  console.log 'whisked: ',file
                  
              when 'video'
                switch file.ext
                  when 'webm','mp4','mov','m4v'
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
                      file.save (err)=>
                        @emit 'sync', 'file', { method: 'update', model: file, options: { teacherId: file.owner } }
                  else
                    @encode file


      when 'update'
        {_id: id} = model
        delete model._id

        @findById id, (err,file)->
          _.extend file, model
          file.modified = Date.now()
          file.save (err)=>
            cb err, file
            
      when 'delete'
        {_id: id} = model
        @findById id, (err, file)->
          file.remove (err)=>
            cb err, id


module.exports = mongoose.model 'file', FileSchema
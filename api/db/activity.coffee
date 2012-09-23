

CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
mongoose.connect "mongoose://localhost/lingualab"
moment = require 'moment'

_ = require 'underscore'
util = require 'util'

ActivitySchema = new Schema {
  created: { type: Date, default: Date.now() }
  modified: { type: Date, default: Date.now() }
  owner: { type: ObjectId, ref: 'User' }
  labState: {}
  request: Number
}

ActivitySchema.statics =
  
  sync: (params,cb)->

    {method, model, options} = params

    switch method

      when 'create'

        if options.role in ['teacher','admin']
          activity = new @ model
          activity.modified = moment().valueOf()
          activity.created = moment().valueOf()

          activity.owner = options.userId


          activity.save (err)=>
            cb err, activity

      when 'read'

        if (id = model?._id ? options?.id)
          @findById id, cb

        else
          if options.role is 'student'
            @find { owner: options.teacherId }, cb

          if options.role is 'teacher'
            @find { owner: options.userId }, cb

      when 'update'
        console.log 'activity update reached', method, model, options
        {_id: id} = model
        delete model._id
        delete model.owner

        @findById id, (err,activity)->
          _.extend activity, model
          activity.modified = Date.now()
          activity.save (err)=>
            cb err, activity
              
      when 'delete'
        {_id: id} = model
        
        @findById id, (err, activity)->
          if err then cb err
          else if activity
            activity.remove (err)=>
              cb err, id



module.exports = mongoose.model 'activity', ActivitySchema



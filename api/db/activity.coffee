

CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
db = mongoose.createConnection 'localhost','lingualab'
moment = require 'moment'

_ = require 'underscore'
util = require 'util'

ActivitySchema = new Schema {
  created: { type: Date, default: Date.now() }
  modified: { type: Date, default: Date.now() }
  owner: { type: ObjectId, ref: 'User' }
  title: String
  tags: String
  labState: {}
  instructions: {}
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

module.exports = db.model 'activity', ActivitySchema
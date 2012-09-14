CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
db = mongoose.createConnection 'localhost','lingualab'
moment = require 'moment'

_ = require 'underscore'
util = require 'util'

ResponseSchema = new Schema {
  created: { type: Date, default: Date.now() }
  modified: { type: Date, default: Date.now() }
  owner: { type: ObjectId, ref: 'User' }
  student: { type: ObjectId, ref: 'Student' }
  activity: { type: ObjectId, ref: 'Activity' }
  context: {}
  answers: [{}]
}

ResponseSchema.statics =

  sync: (params,cb)->

    {method, model, options} = params

    switch method


      when 'read'

        if options.role is 'teacher'
          @find {owner: options.userId}, cb

      when 'create'

        response = new @ model
        response.modified = moment().valueOf()
        response.created = moment().valueOf()

        response.student = options.userId


        response.save (err)=>
          cb err, response

          @emit 'new', response


module.exports = db.model 'response', ResponseSchema
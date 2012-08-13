CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
User = require './user'
_ = require 'underscore'

mongoose.connect "mongoose://localhost/lingualab"

LabSchema = new Schema {
  created: {type: Date, default: Date.now()}
  modified: {type: Date, default: Date.now()}
  teacherId: {type: ObjectId, ref: User}
  state: {}
}


LabSchema.statics =
  
  sync: (data,cb)->

    {method,model,options} = data

    switch method

      when 'read'
        if options.role is 'teacher'
          @find { teacherId: options.userId }, cb

      when 'create'
        if options.role in ['teacher','admin']

          lab = new @ model
          lab.teacherId = options.userId

          lab.save (err)=>
            cb err, lab


module.exports = mongoose.model 'lab', LabSchema
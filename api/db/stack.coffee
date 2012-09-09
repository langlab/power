CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
User = require './user'
_ = require 'underscore'

db = mongoose.createConnection 'localhost','lingualab'

StackSchema = new Schema {
  created: {type: Date, default: Date.now()}
  modified: {type: Date, default: Date.now()}
  teacherId: {type: ObjectId, ref: User}
  title: {type: String}
  tags: {type: String}
  cards: [{}]
}

StackSchema.statics =
  
  sync: (data,cb)->
    {method, model, options} = data
    #console.log 'student sync reached', method, model, options
    switch method
      
      when 'read'
        @find {}, cb

      when 'create'
        stack = new @ model
        stack.save (err)=> 
          cb err, stack


module.exports = Stack = db.model 'stack', StackSchema
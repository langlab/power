#CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
util = require 'util'

mongoose.connect "mongoose://localhost/lingualab"

UserSchema = new Schema {
  role: { type: String, enum: ['teacher','student'], default: 'teacher' }
  created: { type: Date, default: Date.now() }
  lastLogin: Date 
  twitterId: { type: Number, index: true }
  twitterName: String
  twitterData: {}
  profileThumb: String
  name: String
  login: String
}

UserSchema.statics =

  auth: (twitterData,cb)->
    @findOne { twitterId: twitterData.id }, (err, user)=>
      if user then cb err, user
      else
        newUser = new @ {
          twitterId: twitterData.id
          twitterData: twitterData
        }

        newUser.save (err)->
          cb err, newUser

  sync: (data,cb)->
    { method, model, options } = data

    switch method

      when 'read'

        console.log 'user:read'
        if (id = model?._id ? options?.id)
          console.log 'finding user id:',id
          @find {_id: id}, (err,user)=>
            console.log 'user found: ',user
            cb err, user
        else
          if options.role is 'admin'
            @find {}, (err,users)=>
              console.log err users



module.exports = mongoose.model 'user', UserSchema
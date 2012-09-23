#CFG = require '../../conf'
{Schema} = mongoose = require 'mongoose'
{ObjectId} = Schema
util = require 'util'
_ = require 'underscore'
Student = require './student'
Activity = require './activity'

stripe = require('stripe')('Wa7o9S9HS8mZz6wrvkAXKRpaxFxCXqZT')

mongoose.connect "mongoose://localhost/lingualab"

UserSchema = new Schema {
  role: { type: String, enum: ['teacher','student'], default: 'teacher' }
  created: { type: Date, default: Date.now() }
  lastLogin: Date 
  twitterId: { type: Number, index: true }
  twitterName: String
  twitterUser: String
  twitterData: {}
  profileThumb: String
  teacherName: { type: String, default: '' }
  email: { type: String, default: '', validate: [ /(^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$)|(^$)/, 'enter a valid email address (or none)'] }
  emailPref: { type: String, default: 'never' }
  about: { type: String, default: '' }
  name: String
  login: String
  piggyBank: { type: Number, default: 0 }
  online: { type: Boolean, default: false }
  currentActivity: { type: ObjectId, ref: Activity }
  labState: {}
  allTags: {}
}

UserSchema.methods =
  
  getLab: ->
    #console.log 'hi'


UserSchema.statics =

  setOnline: (id)->
    @findById id, (err,user)=>
      if user
        user.online = true
        user.save()
        @emit 'change:online', user
  
  setOffline: (id)->
    if id is 'all'
      @update { online: true }, { $set: { online: false } }, false, true
    else
      @findById id, (err, user)=>
        if user
          user.online = false
          user.save()
          @emit 'change:online', user

  changePennies: (id,byAmount,cb)->
    @findById id, (err,user)=>
      if err then cb err
      else
        if user.piggyBank + byAmount >= 0
          user.piggyBank += byAmount
          user.save (err)=>
            @emit 'change:piggyBank', user
            cb err

  buyPennies: (token,id,charge,cb)->
    @findById id, (err,user)=>
      if not err
        stripe.charges.create charge, (err,resp)=>
          if not err
            user.piggyBank += parseInt(charge.amount,10)
            user.save (err)=>
              @emit 'change:piggyBank', user
          cb err,resp

  auth: (twitterData,cb)->
    @findOne { twitterId: twitterData.id }, (err, user)=>
      twitterModel =
        twitterId: twitterData.id
        twitterData: twitterData
        twitterUser: twitterData.screen_name
        twitterName: twitterData.name
        twitterImg: twitterData.profile_image_url_https

      if user
        # update the user's twitter data
        _.extend user, twitterModel
        user.save (err)->
          cb err, user
      else
        # create a user and set the twitter data
        newUser = new @ twitterModel
        newUser.save (err)->
          cb err, newUser

  sync: (data,cb)->
    { method, model, options } = data

    switch method

      when 'read'

        if (id = model?._id ? options?.id)
          @find {_id: id}, (err,user)=>
            cb err, user

        else if (twitterUser = model.twitterUser)
          @findOne {twitterUser: twitterUser}, (err,user)=>
            # TODO: prune the data passed to the login page
            cb err, user

        else if options.role is 'admin'
          @find {}, (err,users)=>
            cb err users

      when 'update'

        if options.role is 'teacher'
          @findById model._id, (err,user)->
            delete model._id
            _.extend user, model
            user.save (err)->
              cb err, user

      when 'charge'

        if options.role is 'teacher'
          @buyPennies options.token, model._id, options.charge, cb

        



module.exports = User = mongoose.model 'user', UserSchema

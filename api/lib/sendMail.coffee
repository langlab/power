
nodemailer = require 'nodemailer'
_ = require 'underscore'

module.exports = (options, cb)->

  # options are:
  # - to
  # - subject
  # - html
  # - from (optional)

  transport = nodemailer.createTransport "SES", {
    AWSAccessKeyID: "AKIAIUJTVW7ZLSILOJRA"
    AWSSecretKey: "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"
  }

  _.defaults options, {
    from: 'teacher@langlab.org'
  }

  _.extend options, {
    generateTextFromHTML: true
  }

  transport.sendMail options, cb
  



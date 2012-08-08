
nodemailer = require 'nodemailer'
_ = require 'underscore'

module.exports = (options, cb)->

  # options are:
  # - to
  # - subject
  # - html

  transport = nodemailer.createTransport "SES", {
    AWSAccessKeyID: "AKIAIUJTVW7ZLSILOJRA"
    AWSSecretKey: "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"
  }

  _.extend options, {
    generateTextFromHTML: true
    from: "georgedyer@me.com"
  }

  transport.sendMail options, cb
  



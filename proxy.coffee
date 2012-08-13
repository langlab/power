fs = require("fs")
http = require("http")
https = require("https")
httpProxy = require("http-proxy")
crypto = require 'crypto'

getCredentialsContext = (cer)->
  return crypto.createCredentials({
    key:  fs.readFileSync "./certs/#{cer}.key.pem"
    cert: fs.readFileSync "./certs/#{cer}.pem"
  }).context


certs =
  'langlab.org': getCredentialsContext 'langlab.org'
  'api.langlab.org': getCredentialsContext 'api.langlab.org'


options =
  https:
    SNICallback: (hostname)->
      return certs[hostname];
  hostnameOnly: true
  router:
    'langlab.org':  'localhost:8181',
    'api.langlab.org': 'localhost:8282'


httpProxy.createServer(options).listen 443


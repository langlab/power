doctype 5
html lang:'en', ->

  head ->

    title 'welcome'
    meta charset:'utf-8'
    meta name:"viewport", content:"width=device-width, initial-scale=1.0"

    # styles
    link rel:'stylesheet', href:'/css/bootstrap.css'
    link rel:'stylesheet', href:'/css/font-awesome.css'
    link rel:'stylesheet', href:'/css/index.css'

  body ->
    div class:'main container', ->

    # scripts
    script type:'text/javascript',src:"http://#{@CFG.SIO.HOST}/socket.io/socket.io.js"
    script type:'text/javascript',src:'/js/ck.js'
    script type:'text/javascript',src:'/js/vendor.js' # everything besides sockets

    # this will inject the following to global namespace:
    #   - session and user data
    #   - application configuration data
    #   - the socket connection
    #   - the injected script will be removed from the DOM for added security

    clientData = 
      session: 
        id: @session.id
        expires: @session.cookie.expires
        lastAccess: @session.lastAccess
        data: @session
      CFG: @CFG.CLIENT()

    script id:'sessionBootstrap', type:'text/javascript', """

      window.app = #{ JSON.stringify clientData }
      window.app.sock = window.io.connect('http://#{ @CFG.SIO.HOST }')

      setTimeout(function() { $('#sessionBootstrap').remove(); }, 500 );
    """

    # client-side app for all users
    script type:'text/javascript',src:'/js/common.js'


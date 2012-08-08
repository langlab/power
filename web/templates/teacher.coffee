doctype 5
html lang:'en', ->

  head ->

    title 'teacher'
    meta charset:'utf-8'
    meta name:"viewport", content:"width=device-width, initial-scale=1.0"

    # styles
    link rel:'stylesheet', href:'/css/bootstrap.css'
    link rel:'stylesheet', href:'/css/font-awesome.css'
    link rel:'stylesheet', href:'/css/index.css'

  body ->
    div class:'main container', ->

    # scripts
    script type:'text/javascript',src:"http://api.lingualab.io/socket.io/socket.io.js"
    script type:'text/javascript',src:'http://api.filepicker.io/v0/filepicker.js'
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
        user: @user
        files: @files
        students: @students
      CFG: @CFG.CLIENT()

    script id:'sessionBootstrap', type:'text/javascript', """

      window.data = #{ JSON.stringify clientData }
      window.sock = window.io.connect('http://api.lingualab.io')

      setTimeout(function() { $('#sessionBootstrap').remove(); }, 500 );
    """

    # client-side app for all users
    script type:'text/javascript',src:'/js/common.js'
    script type:'text/javascript',src: '/js/teacher.js'

# main app module

module 'App', (exports,top)->

  class Model

    constructor: ->
      @socketConnect()
      
      @data =
        teacher: new Teacher 

      @views =
        main: new Views.Main { model: @data.teacher }

      @router = new Router @data, @views

      @data.teacher.set 'twitterUser', document.location.pathname.split('/')[1]
      

    socketConnect: ->
      console.log 'sockconn'
      @connection = window.sock = window.io.connect "https://#{data.CFG.API.HOST}"
      @connectionView = new App.Connection.Views.Main { model: @connection }

      @connection.on 'connect', =>
        @data.teacher.fetch {
          error: (m,e)=>
            conseol.log error
            console.log m,e
          success: =>
            Backbone.history.start()
        }


  [exports.Model] = [Model]

  class Teacher extends Backbone.Model
    syncName:'user'

  class Login extends Backbone.Model

    syncName:'student'

    defaults:
      email: '@'
      password: '*'
      forgot: false
      attempts: 0

    validate: (attrs)->
      { email, password } = attrs
      errs = []

      if not email.match /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
        errs.push { type: 'email', message:'invalid email address' }
      
      return if errs.length then errs else null

    getKey: (cb)->
      console.log @toJSON()
      window.sock.emit 'auth', @toJSON(), cb
      # $.getJSON "http://api.lingualab.io/studentAuth?callback=?", @toJSON(), cb

    emailKey: (cb)->
      params =
        email: @get 'email'
        password: '*'
        forgot: true
      console.log params
      window.sock.emit 'auth', params, cb
      #$.getJSON "http://api.lingualab.io/studentAuth?callback=?", params, cb

  
  exports.Views = Views = {}

  class Views.Main extends Backbone.View
    className: 'teacher-page-view container'
    tagName: 'div'

    initialize: ->
      @login = new Login
      @views =
        login: new App.Views.Login { model: @login }

      @model.on 'reset', @render, @
      @model.on 'change', @render, @


    template: ->
      div class:'page-header', ->
        div class:'row', ->
          div class:'span1', -> 
            img src:"#{ @get 'twitterImg' }"
          div class:'span10', -> 
            h1 " #{ @get('teacherName') or @get('twitterName') }"
            if @get('email')
              a href:"mailto:#{@get('email')}", -> i class:'icon-envelope', " #{@get 'email'}"

      div class:'login-cont', ->

    render: ->
      super()
      @views.login.render().open @$('.login-cont')
      @open()
      console.log @model
      @


  class Views.NoTeacher extends Backbone.View

  # sample view
  class Views.Login extends Backbone.View
    className: 'login-screen'
    tagName: 'div'

    initialize: ->
      @model.on 'change:attempts', =>
        @model.getKey (err,key)=>
          if key then window.location = "/studentAuth/#{key}"
          else
            #console.log resp
            @showError err

      @model.on 'change:forgot', =>
        @model.emailKey (err,resp)=>
          if resp
            @clearErrors()
            @$('.message').addClass('alert').text 'Check your email for a link to sign in!'
            @$('.i-forgot').hide()
          else
            @model.set 'forgot', 'false', {silent: true}
            @showError err


    events:
      'click .sign-in':'signIn'
      'click .i-forgot':'iForgot'
      'keyup .password': (e)-> if e.which is 13 then @signIn()


    clearErrors: ->
      @$(".control-group.error .help-block").text ''
      @$(".control-group.error").removeClass('error').addClass('success')

    showError: (errs)->
      if not _.isArray errs then errs = [ errs ]

      @clearErrors()

      for err in errs
        @$(".#{err.type}-control").removeClass('success').addClass 'error'
        @$(".#{err.type}-control").find(".help-block").text err.message or 'Invalid ',err.type

      @$(".#{errs[0].type}").select()

    iForgot: ->
      @$('.password-control').hide()
      @$('.sign-in').hide()
      @model.set {
        email: @$('.email').val()
        password: '*'
        forgot: true
      }, {
        error: (m,errs)=> @showError errs
      }


    signIn: (event)->

      @model.set {
        email: @$('.email').val()
        password: @$('.password').val() or '*'
        attempts: 1 + @model.get 'attempts'
      }, {
        error: (m,errs)=> @showError errs
      }

    template: ->
      div class:'row', ->

        div class:'span4 student-header well', ->
          div class:'',->
            h2 ' Welcome, students!'
            p "Sign in below. If you forget your password, don't worry, it can be emailed to you."
          form class:'', ->
            div class:'control-group email-control', ->
              div class:'controls', ->
                div class:'input-prepend', ->
                  span class:'add-on icon-envelope'
                  input type:'text', class:'email', placeholder:'email'
                  span class:'help-block'
            div class:'control-group password-control', ->
              div class:'controls', ->
                div class:'input-prepend', ->
                  span class:'add-on icon-key'
                  input type:'password', class:'password', placeholder:'password'
                  span class:'help-block'

            div class:'message', ->
          div class:'btn-toolbar', ->
            button class:'sign-in btn btn-info icon-signin', ' Sign in'
            button class:'i-forgot btn btn-warning', ->
              text 'I forgot my '
              i class:'icon-key'



    render: ->
      @$el.html ck.render @template
      @delegateEvents()
      @


  class Router extends Backbone.Router

    initialize: (@data,@views)->

    routes:
      '':'home'

    home: ->
      console.log 'no place like home'
      #@clearViews()
      
      
window.app = new App.Model()

  

$ ->
  console.log 'hi'

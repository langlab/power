# main app module

module 'App', (exports,top)->

  class Login extends Backbone.Model

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
      $.getJSON "http://api.lingualab.io/studentAuth?callback=?", @toJSON(), cb

    emailKey: (cb)->
      params =
        email: @get 'email'
        password: '*'
        forgot: true

      $.getJSON "http://api.lingualab.io/studentAuth?callback=?", params, cb

  
  exports.Views = Views = {}

  # sample view
  class Views.Main extends Backbone.View
    className: 'container login-screen'
    tagName: 'div'

    initialize: ->
      @model.on 'change:attempts', =>
        @model.getKey (resp)=>
          if resp.key then window.location = "/studentAuth/#{resp.key}"
          else
            console.log resp
            @showError resp.err

      @model.on 'change:forgot', =>
        @model.emailKey (resp)=>
          if resp.success
            @clearErrors()
            @$('.message').addClass('alert').text 'Check your email for a link to sign in!'
            @$('.i-forgot').hide()
          else
            @model.set 'forgot', 'false', {silent: true}
            @showError resp.err


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

        span class:'span12 logo', ->
          h2 ->
            i class:'icon-beaker'
            text " lingualab.io"

      div class:'row', ->

        div class:'span5 teacher-header', ->
          h2 'Teachers'
          a href:'/auth/twitter',class:'btn btn-info', ->
            i class:'icon-twitter icon-large btn-large'
            span ' Sign in with Twitter'


        div class:'span4 student-header', ->
          h2 'Students'
          form ->
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


  class exports.Controller extends Backbone.Router

    initialize: ->
      @login = new Login
      @views =
        main: new App.Views.Main { model: @login }

      

    clearViews: (exceptFor)->
      view.remove() for key,view of @views when key isnt exceptFor

    routes:
      '':'home'
      'timeline':'timeline'
      'timer':'timer'

    home: ->
      @clearViews()
      @views.main.render().open()

    timeline: ->
      @clearViews()

      @activity = new App.Activity.Model {
        duration: 600
        events: [
          { start: 10, pause: true, duration: 5 }
          { start: 30, pause: false, duration: 10}
        ]
      } 

      @views.tl = new App.Activity.Views.Timeline({model: @activity})
      @views.tl.render().open()

    timer: ->
      @clearViews()
      console.log 'route: timer'
      @t = new App.Activity.Timer()
      @t.addCues [
        { at: 4, fn: -> console.log 'hi 4' }
        { at: 10, fn: -> console.log 'hi 10' }
        { at: 4, fn: -> console.log 'hello 4'}
        { at: 11, fn: -> console.log 'yo yo'}
      ]

      throttledLog = _.throttle(((txt)-> console.log txt), 200, true)

      @t.on 'status', (data)-> 
        msg = "#{data.name} at #{data.secs}s"

      @v = new App.Activity.Views.Timer { model: @t }

      @v.render().open()


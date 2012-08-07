
module 'App.Student', (exports,top)->

  class Model extends Backbone.Model

    fullName: -> "#{@get('firstName')} #{@get('lastName')}"

  exports.Views = Views = {}

  class Views.TopBar extends Backbone.View
    tagName: 'div'
    className: 'top-bar navbar navbar-fixed-top'

    updateNav: ->
      rt = Backbone.history.fragment.split('/')[0]
      @$('ul.nav li').removeClass 'active'
      @$("ul.nav a[href=##{rt}]").parent('li').addClass 'active'
      @

    template: ->
      div class:'navbar-inner', ->
        div class:'container', ->

          a class:'btn btn-navbar', 'data-toggle':'collapse', 'data-target':'.nav-collapse', ->
            span class:'icon-beaker icon-large'
            span class:'icon-reorder icon-large'

          div class:'nav-collapse', ->
            ul class:'nav', ->
              li ->
                a class:'brand pull-left', href:'#', ->
                  i class:'icon-bolt'
              li class:'divider-vertical'
              li ->
                a href:'#lab', ->
                  i class:'icon-headphones'
                  text ' Lab'
              li ->
                a href:'#practice', ->
                  i class:'icon-refresh'
                  text ' Practice'
              li ->
                a href:'#achievements', ->
                  i class:'icon-trophy'
                  text ' Achievements'

              

            ul class:'nav pull-right', ->
              li class:'user', ->
                span ->
                  i class: 'icon-user'
                  text " #{@fullName()} "
              li class:'divider-vertical'
              li ->
                a href:'/studentLogout', ->
                  i class:'icon-signout'


  class Controller extends top.App.Controller
    initialize: ->
      @user = new Model top.app.session.user

      @views =
        topBar: new Views.TopBar { model: @user }
        lab: new App.Lab.Views.Main

      @showTopBar()


    routes:
      '':'home'

    showTopBar: ->
      @views.topBar.render().open()

    home: ->
      @clearViews 'topBar'




  

  [exports.Controller] = [Controller]

module 'App.Student', (exports,top)->

  class Model extends Backbone.Model
    syncName: 'student'
    idAttribute: '_id'

    fromDB: (data)->
      {method,model,options} = data

      switch method
        when 'piggyBank'
          @set 'piggyBank', model.piggyBank

    toggleHelp: ->
      @set 'help', not @get('help')
      @sync 'help', @toJSON(), {
        success: => log 'asked for help'
      }



  [exports.Model] = [Model]
  
  exports.Views = Views = {}

  class Views.TopBar extends Backbone.View
    tagName: 'div'
    className: 'top-bar navbar navbar-fixed-top'

    initialize: ->
      @model.on 'change:piggyBank', (m,v)=>
        @render()

    events:
      'click .get-help': -> 
        @model.toggleHelp()
        @render()

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
              li class:'user', ->
                span ->
                  i class: 'icon-user'
                  text " #{@get 'name'} "
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

            button class:"btn btn-small icon-bullhorn get-help pull-right btn-#{if @get('help') then 'warning active' else 'danger'}", 'data-toggle':'button', " #{if @get('help') then 'Getting help...' else ' Ask for help'}"

            ul class:'nav pull-right', ->
              
              li class:'divider-vertical'
              li class:'heartbeats', ->
                a href:'#', ->
                  i class: 'icon-heart'
                  span class:'piggyBank', " #{@get 'piggyBank'}"
              li class:'divider-vertical'
              li ->
                a href:'/studentLogout', ->
                  i class:'icon-signout'



  
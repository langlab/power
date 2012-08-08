
module 'App.Teacher', (exports,top)->

  class Model extends Backbone.Model

  exports.Model = Model

  exports.Views = Views = {}

  class Views.FlashMessage extends Backbone.View
    tagName:'div'
    className:'alert fade in flash-message'

    initialize: (options)->
      @message = options.message
      @type = options.type
      @time = options.time

    render: ->
      @$el.text @message
      @$el.alert()
      @$el.addClass "alert-#{@type}"
      @$el.appendTo 'body'
      @$el.on 'closed', =>
        @remove()
      
      if @time
        wait @time, => @$el.alert('close')

  class Views.TopBar extends Backbone.View
    tagName: 'div'
    className: 'top-bar navbar navbar-fixed-top'

    updateNav: (rt)->
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
                a href:'#files', ->
                  i class:'icon-briefcase'
                  text ' Files'
              li ->
                a href:'#students', ->
                  i class:'icon-group'
                  text ' Students'

              li ->
                a href:'#lab', ->
                  i class:'icon-headphones'
                  text ' Lab'

            ul class:'nav pull-right', ->
              li class:'user', ->
                span ->
                  img src:"#{@get('twitterData').profile_image_url}"
                  text " #{@get('twitterData').name} "
              li class:'divider-vertical'
              li ->
                a href:'/logout', ->
                  i class:'icon-signout'
            
    render: ->
      @$el.html ck.render @template, @model
      @


  
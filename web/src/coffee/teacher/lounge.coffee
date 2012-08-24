
module 'App.Lounge', (exports,top)->

  class Model extends Backbone.Model


  class Collection extends Backbone.Collection
    model: Model


  [exports.Model, exports.Collection] = [Model,Collection]

  exports.Views = Views = {}

  class Views.Main extends Backbone.View
    tagName: 'div'
    className: 'lounge-main container'

    initialize: ->


    template: ->

      div class: 'row', ->
        ul class:'thumbnails', ->
          for i in [1..40]
            li class:'span4', ->
              span class:'thumbnail', ->
                img class:'img-circle', src:'http://placehold.it/100x100'
                div class:'caption', ->
                  h4 "Table #{i}"
                  p "Description for the table"


        ###
        span class:'chats span3', ->
          for i in [1..20]
            div class:"accordion-group", ->
              div class:'accordion-heading', ->
                span class:'accordion-toggle icon-edit', 'data-toggle':'collapse', 'data-target':".lounge-#{ i }", ->
                  text " Table #{ i }"
                  span class:'close pull-right', ->
              div class:"collapse lounge-#{ i } accordion-body", ->
                div class:'accordion-inner', ->
                  div class:"lounge-cont-#{ i }", ->
        ###
    render: ->
      super()
      @


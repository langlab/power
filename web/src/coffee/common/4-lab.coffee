
module 'App.Lab', (exports, top)->
  

  class Model extends Backbone.Model



  exports.Views = Views = {}

  class Views.Main extends Backbone.View

    initialize: ->
      @model = new Model
      @media = new App.Media.Views.Player
      
    tagName: 'div'
    className: 'lab'

    template: ->

      div class:'media-cont', ->

      div class:'message-cont', ->
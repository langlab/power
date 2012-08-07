

module 'App.Media', (exports, top)->

  class Model extends Backbone.Model



  exports.Views = Views = {}
  
  class Views.Player extends Backbone.Model


    tagName: 'div'
    className: 'media-player'

    template: ->
      video ->
        source src:''

  [exports.Model] = [Model]

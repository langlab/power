module 'App.Lab', (exports, top)->

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'


  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->


    template: ->
      div class:'row-fluid', ->
        div class:'media-cont span6', ->
          p 'media'

        div class:'message-cont span6', 'contenteditable':'true', ->
          "#{@get('status').message}"


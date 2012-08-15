module 'App.Lab', (exports, top)->

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: ->  
      @state = new State

    fromDB: (data)->
      console.log 'fromDB: ',data
      {method,model,options} = data

      switch method

        when 'update:state'
          console.log 'update:state recvd:',data
          @state.set model


  class State extends Backbone.Model

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'




  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->

      @model.state.on 'change', =>
        @render()


    saveMessage: (e)->
      @model.set 'message', @$('.message-cont').html()

    template: ->
      div class:'row-fluid', ->
        div class:'media-cont span6', ->
          p 'media'

        div class:'message-cont span6', ->
          "#{@state.get 'message'}"




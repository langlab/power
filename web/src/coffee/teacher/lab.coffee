module 'App.Lab', (exports, top)->

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: ->
      @state = new State { teacherId: @get('teacherId') }

      @state.on 'change', @updateState, @

    startSession: ->
      @sync 'startSession', @, {
        success: (data)=>
          console.log 'session started: ',data
      }

    stopSession: ->
      @sync 'stopSession', @, {
        success: (data)=>
          console.log 'session stopped: ',data
      }

    addStudent: (studentId)->
      @sync 'add:student', @, {
        studentIds: [studentId]
        success: (data)=>
          console.log 'student added: ',data
      }

    updateState: ->
      console.log 'updating state...'
      @sync 'update:state', @state, {
        success: (err,data)=>
          console.log 'state updated: ',data
      }

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
      @model.startSession()

    events:
      'keyup .message-cont':'saveMessage'

    saveMessage: (e)->
      @model.state.set 'message', @$('.message-cont').html()

    template: ->
      div class:'row-fluid', ->
        div class:'media-cont span6', ->
          p 'media'

        div class:'message-cont span6', 'contenteditable':'true', ->
          "#{@state.get('message')}"




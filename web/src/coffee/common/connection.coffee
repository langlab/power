
module 'App.Connection', (exports, top)->

  exports.Views = Views = {}

  class Views.Main extends Backbone.View
    tagName:'div'
    className:'modal fade hide'

    initialize: ->
      @render()
      console.log @

      @model.on 'disconnect', =>
        @startTimer()
        @open()

      @model.on 'connect', =>
        Backbone.Model::io = Backbone.Collection::io = Backbone.View::io = window.sock

      @model.on 'reconnect', =>
        Backbone.Model::io = Backbone.Collection::io = Backbone.View::io = window.sock
        @stopTimer()
        @close()


      @model.on 'reconnecting', =>
        @stopTimer()
        @$('.manual-reconnect').text  ' Try to reconnect now'
        @startTimer()

    events:
      'click .manual-reconnect':'reconnect'

    startTimer: ->
      @t = 0
      @timer = doEvery 200, =>
        @t += 200
        @$('.time-till-reconnect').text "#{Math.floor((@model.socket.reconnectionDelay - @t)/1000)}s" 

    stopTimer: ->
      if @timer then clearTimeout @timer

    reconnect: ->
      @$('manual-reconnect').text 'Trying...'
      @model.socket.reconnect()

    template: ->
      div class:'modal-body',->
        div class:'status', ->
          i class:'icon-cloud'
          h3 'Your connection to the server was lost.'
          p 'Please check that you are still connected to the internet'
          p ->
            text "Lingualab has failed to connect, will automatically try to reconnecting in "
            span class:'time-till-reconnect'

      div class:'modal-footer',->
        button class:'btn btn-warning icon-signal manual-reconnect', ' Try to reconnect now'

    close: ->
      @$el.modal 'hide'

    open: ->
      @$el.modal 'show'

    render: ->
      super()
      @$el.appendTo 'body'
      @
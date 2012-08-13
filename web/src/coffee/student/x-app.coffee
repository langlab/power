
module 'App', (exports, top)->

  class Model

    constructor: ->
      @socketConnect()
      
      #receives and routes sync updates
      @fromDB()

      @data =
        student: new App.Student.Model top.data.session.student

      @views =
        topBar: new App.Student.Views.TopBar { model: @data.student }

      @router = new Router @data, @views
      Backbone.history.start()


    fromDB: ->
      @connection.on 'sync', (service, data)=>
        console.log 'service',service,'data',data
        switch service
          when 'student'
            @data.student.fromDB(data)

    socketConnect: ->
      @connection = window.sock = window.io.connect "https://#{data.CFG.API.HOST}"
      @connectionView = new App.Connection.Views.Main { model: @connection }

  [exports.Model] = [Model]
  
  class Router extends Backbone.Router

    initialize: (@data, @views)->

      @showTopBar()


    routes:
      '':'home'

    showTopBar: ->
      @views.topBar.render().open()

    home: ->
      #@clearViews 'topBar'


$ ->
  window.app = new App.Model
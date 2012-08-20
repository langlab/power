
module 'App', (exports, top)->

  class Model

    constructor: ->
      @socketConnect()
      
      #receives and routes sync updates
      @fromDB()

      @data =
        student: new App.Student.Model top.data.session.student
        lab: new App.Lab.Model

      @views =
        topBar: new App.Student.Views.TopBar { model: @data.student }
        lab: new App.Lab.Views.Main { model: @data.lab }

      @router = new Router @data, @views
      Backbone.history.start()


    fromDB: ->
      @connection.on 'sync', (service, data)=>
        #log 'service',service,'data',data
        switch service
          when 'student'
            @data.student.fromDB(data)

          when 'lab'
            if data.method is 'join'
              @router.navigate 'lab', true

            @data.lab.fromDB(data)

    socketConnect: ->
      @connection = window.sock = window.io.connect "https://#{data.CFG.API.HOST}"
      @connectionView = new App.Connection.Views.Main { model: @connection }

  [exports.Model] = [Model]
  
  class Router extends Backbone.Router

    initialize: (@data, @views)->

      @showTopBar()


    routes:
      '':'home'
      'lab':'lab'

    showTopBar: ->
      @views.topBar.render().open()

    home: ->
      #@clearViews 'topBar'

    lab: ->
      @clearViews 'topBar'
      @views.lab.render().open()


$ ->
  window.app = new App.Model
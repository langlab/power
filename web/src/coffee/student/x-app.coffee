
module 'App', (exports, top)->

  class Model

    constructor: ->
      @sock = top.window.sock
      
      #receives and routes sync updates
      @fromDB()

      @data =
        student: new App.Student.Model top.data.session.student

      @views =
        topBar: new App.Student.Views.TopBar { model: @data.student }

      @router = new Router @data, @views

    fromDB: ->
      @sock.on 'sync', (service, data)=>
        console.log 'service',service,'data',data
        switch service
          when 'student'
            @data.student.fromDB(data)

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
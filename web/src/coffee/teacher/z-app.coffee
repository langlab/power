
module 'App', (exports, top)->

  class Model
    
    constructor: ->

      window.filepicker.setKey('Ag4e6fVtyRNWgXY2t3Dccz')
      Stripe.setPublishableKey('pk_04LnDZEuRgae5hqjKjFaWjFyTYFgs');

      @socketConnect()

      #receives and routes sync updates
      @fromDB()

      @data =
        teacher: new App.Teacher.Model top.data.session.user
        filez: new App.File.Collection()
        students: new App.Student.Collection()
        labs: new App.Lab.Collection()

      
      @views =
        topBar: new App.Teacher.Views.TopBar { model: @data.teacher }
        filez: new App.File.Views.Main { collection: @data.filez }
        students: new App.Student.Views.Main { collection: @data.students }
        profile: new App.Teacher.Views.Profile { model: @data.teacher }
        piggy: new App.Teacher.Views.Account { model: @data.teacher }
        #labs: new App.Lab.Views.Main { model}
      

      @router = new Router @data, @views
      

      @fetched = 0
      
      # when all fetching is done, start the router

      fetcher = (col)=>
        col.fetch {
          success: =>
            @fetched++
            if @fetched is (_.keys @data).length - 1 then Backbone.history.start()
        }

      wait 200, =>
        fetcher @data.filez
        fetcher @data.students
        fetcher @data.labs

    fromDB: ->
      @connection.on 'sync', (service, data)=>
        console.log 'service',service,'data',data
        switch service
          when 'file'
            @data.filez.fromDB(data)
          when 'student'
            @data.students.fromDB(data)
          when 'user'
            @data.teacher.fromDB(data)

    socketConnect: ->
      @connection = window.sock = window.io.connect "https://#{window.data.CFG.API.HOST}"

      @connectionView = new App.Connection.Views.Main { model: @connection }




  class Router extends Backbone.Router

      initialize: (@data,@views)->
        
        @showTopBar()

      routes:
        '/':'home'
        'files':'files'
        'students':'students'
        'lab':'lab'
        'lab/:id':'loadLab'

      
      showTopBar: ->
        @views.topBar.render().open()

      home: ->
        @clearViews()
        #@views.layout = new App.Layout.Main
        #@views.layout.render().open()

      profile: ->
        @views.profile.render()

      files: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'files'
        @views.filez.render().open()

      fileDetail: (id)->
        @clearViews 'topBar'
        @views.detail = new App.File.Views.Detail { model: @data.filez.get(id) }
        @views.detail.render().open()

      students: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'students'
        @views.students.render().open()

      lab: ->
        @clearViews 'topBar'
        @views.topBar.updateNav()
        @views.lab.render().open()

      loadLab: (id)->
        @clearViews 'topBar'
        @views.labSession = new App.Lab.Views.Main { model: @data.labs.get(id) }
        @views.labSession.render().open()

  [exports.Model,exports.Router] = [Model,Router]


$ ->

  window.app = new App.Model

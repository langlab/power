
module 'App', (exports, top)->

  class Model
    
    constructor: ->
      window.filepicker?.setKey('Ag4e6fVtyRNWgXY2t3Dccz')
      Stripe?.setPublishableKey('pk_04LnDZEuRgae5hqjKjFaWjFyTYFgs');

      #$('applet').hide()
      @socketConnect()

      #receives and routes sync updates
      @fromDB()

      @data =
        teacher: new App.Teacher.Model top.data.session.user
        filez: new App.File.Collection()
        students: new App.Student.Collection()
        
      @data.lab = new App.Lab.Model {}, {
          teacher: @data.teacher
          students: @data.students # for the lab interface
          filez: @data.filez
        }
      
      @views =
        topBar: new App.Teacher.Views.TopBar { model: @data.teacher }
        filez: new App.File.Views.Main { collection: @data.filez }
        students: new App.Student.Views.Main { collection: @data.students }
        profile: new App.Teacher.Views.Profile { model: @data.teacher }
        piggy: new App.Teacher.Views.Account { model: @data.teacher }
        lounge: new App.Lounge.Views.Main
        #lab: new App.Lab.Views.Main { model: @data.lab }
      

      @router = new Router @data, @views
      

      @fetched = 0
      
      # when all fetching is done, start the router

      fetcher = (col)=>
        col.fetch {
          success: =>
            @fetched++
            if @fetched is (_.keys @data).length - 2 then Backbone.history.start()
        }

      wait 200, =>
        fetcher @data.filez
        fetcher @data.students

    fromDB: ->
      @connection.on 'sync', (service, data)=>
        log 'service',service,'data',data
        switch service
          when 'file'
            @data.filez.fromDB(data)
          when 'student'
            @data.students.fromDB(data)
          when 'user'
            @data.teacher.fromDB(data)
          when 'lab'
            @data.lab.fromDB(data)


    tagList: ->
      _.union @data.students.allTags(), @data.filez.allTags()

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
        'student/:id':'studentDetail'
        'lab':'lab'
        'lounge':'lounge'

      
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

      studentDetail: (id)->
        @clearViews 'topBar'
        @views.studentDetail = new App.Student.Views.Detail { model: @data.students.get(id) }
        @views.studentDetail.render().open()

      lab: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'lab'
        @views.lab = new App.Lab.Views.Main { model: @data.lab }
        @views.lab.render().open()

      lounge: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'lounge'
        @views.lounge.render().open()

  [exports.Model,exports.Router] = [Model,Router]


$ ->

  window.app = new App.Model

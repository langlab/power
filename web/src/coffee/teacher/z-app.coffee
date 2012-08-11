
module 'App', (exports, top)->

  class Model
    
    constructor: ->

      #window.filepicker.setKey('Ag4e6fVtyRNWgXY2t3Dccz')
      Stripe.setPublishableKey('pk_04LnDZEuRgae5hqjKjFaWjFyTYFgs');

      @sock = top.window.sock
      
      #receives and routes sync updates
      @fromDB()

      @data =
        teacher: new App.Teacher.Model top.data.session.user
        filez: new App.File.Collection()
        students: new App.Student.Collection()

      
      @views =
        topBar: new App.Teacher.Views.TopBar { model: @data.teacher }
        filez: new App.File.Views.Main { collection: @data.filez }
        students: new App.Student.Views.Main { collection: @data.students }
        profile: new App.Teacher.Views.Profile { model: @data.teacher }
        piggy: new App.Teacher.Views.Account { model: @data.teacher }
        # lab: new App.Lab.Views.Main
      

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

    fromDB: ->
      @sock.on 'sync', (service, data)=>
        console.log 'service',service,'data',data
        switch service
          when 'file'
            @data.filez.fromDB(data)
          when 'student'
            @data.students.fromDB(data)
          when 'user'
            @data.teacher.fromDB(data)




  class Router extends Backbone.Router

      initialize: (@data,@views)->
        
        @showTopBar()

      routes:
        '/':'home'
        'files':'files'
        'students':'students'
        'files/:id':'fileDetail'
        'student/:id':'studentDetail'
        'lab':'lab'
        'profile':'profile'

      
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

  [exports.Model,exports.Router] = [Model,Router]


$ ->

  window.app = new App.Model

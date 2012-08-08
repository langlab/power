
module 'App', (exports, top)->

  class Model
    
    constructor: ->

      window.filepicker.setKey('Ag4e6fVtyRNWgXY2t3Dccz')
      @sock = top.window.sock
      @fromDB()

      @data =
        teacher: new App.Teacher.Model top.data.session.user
        filez: new App.File.Collection()
        students: new App.Student.Collection()

      
      @views =
        topBar: new App.Teacher.Views.TopBar { model: @data.teacher }
        filez: new App.File.Views.Main { collection: @data.filez }
        students: new App.Student.Views.Main { collection: @data.students }
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
        if service is 'file'
          @filez.fromDB(data)




  class Router extends Backbone.Router

      initialize: (@data,@views)->
        
        @showTopBar()

      clearViews: (exceptFor)->
        view.remove() for key,view of @views when key isnt exceptFor

      routes:
        '/':'home'
        'files':'files'
        'students':'students'
        'files/:id':'fileDetail'
        'student/:id':'studentDetail'
        'lab':'lab'

      
      studentView: ->

      showTopBar: ->
        @views.topBar.render().open()

      home: ->
        @clearViews()
        #@views.layout = new App.Layout.Main
        #@views.layout.render().open()

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
        #console.log 'detail model: ',id,@data.students.get(id)
        @clearViews 'topBar'
        model = if id is 'new' then (new App.Student.Model) else @data.students.get(id)
        @views.detail = new App.Student.Views.Detail { model: model }
        @views.detail.render().open()

      lab: ->
        @clearViews 'topBar'
        @views.topBar.updateNav()
        @views.lab.render().open()

  [exports.Model,exports.Router] = [Model,Router]


$ ->

  # if there is a signed-in user, 
  # wait for the next script to start the router

  window.app = new App.Model

  #Backbone.history.start()
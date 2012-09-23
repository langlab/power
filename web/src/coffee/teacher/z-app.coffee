
module 'App', (exports, top)->

  class Loading extends Backbone.View
    className:'loading-view'
    tagName:'div'

    initialize: (@options={})->
      _.defaults @options, {
        loadingText: 'Loading...'
      }
      console.log @options.loadingText
      @on 'open', =>
        @$('.view-cont').center()

    template: ->
      div class:'view-cont', ->
        div class:'spinner-cont'
        h2 class:'loading-text', @loadingText

    render: ->
      @$el.html ck.render @template, @options
      @spinner = new Spinner({top:'0px', left:'0px'}).spin(@$('.spinner-cont')[0])
      @

    close: ->
      @$el.fadeOut 'fast', =>
        @spinner.stop()
        super()

  
  class Model
    collectionsToFetch: ['filez','students','responses','activities']
    
    
    constructor: ->

      @loadingView = new Loading
      @loadingView.render().open()

      window.filepicker?.setKey('Ag4e6fVtyRNWgXY2t3Dccz')
      Stripe?.setPublishableKey('pk_04LnDZEuRgae5hqjKjFaWjFyTYFgs');

      @startHistoryWhenDoneFetching = _.after @collectionsToFetch.length, =>
        @router = new Router @data, @views
        console.log 'starting history'
        Backbone.history.start()
        @loadingView.close()



      #$('applet').hide()
      @socketConnect()

      #receives and routes sync updates
      @fromDB()

      @data =
        teacher: new App.Teacher.Model top.data.session.user
        filez: new App.File.Collection()
        students: new App.Student.Collection()
        responses: new App.Response.Collection()
        activities: new App.Activity.Collection()
        
      @data.lab = new App.Lab.Model {}, {
          teacher: @data.teacher
          students: @data.students # for the lab interface
          filez: @data.filez
          activities: @data.activities
        }
      
      @views =
        topBar: new App.Teacher.Views.TopBar { model: @data.teacher }
        filez: new App.File.Views.Main { collection: @data.filez }
        students: new App.Student.Views.Main { collection: @data.students }
        profile: new App.Teacher.Views.Profile { model: @data.teacher }
        piggy: new App.Teacher.Views.Account { model: @data.teacher }
        lounge: new App.Lounge.Views.Main
        lab: new App.Lab.Views.Main { model: @data.lab }
      

      
      @connection.on 'connect', =>
        for col in @collectionsToFetch
          @data[col].fetch {
            success: => 
              console.log 'fetched ', col
              @startHistoryWhenDoneFetching()
          }

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
          when 'activity'
            @data.activities.fromDB?(data)


    tagList: ->
      _.union @data.students.allTags(), @data.filez.allTags()

    socketConnect: ->
      @connection = window.sock = window.io.connect "https://#{window.data.CFG.API.HOST}"
      @connectionView = new App.Connection.Views.Main { model: @connection }


  class Router extends Backbone.Router

      initialize: (@data,@views)->
        
        @showTopBar()

        # if the teacher has never loaded an activity, select one or create a new one
        if not (activityId = @data.teacher.get('currentActivity'))
          
          newActivity = @data.activities.create {
            labState: {
              settings: {
                title: 'Untitled'
                tags: ''
              }
            }
          }

          @data.lab.loadActivity newActivity
          @views.lab.render().$el.appendTo 'body'

        else
          console.log 'activities: ',@data.activities
          @data.lab.loadActivity @data.activities.get activityId
          @views.lab.render().$el.appendTo 'body'

      routes:
        '/':'home'
        'files':'files'
        'file/:id':'fileDetail'
        'students':'students'
        'student/:id':'studentDetail'
        'student/:id/recording/:file':'studentRecording'
        'lab':'lab'
        'lounge':'lounge'
        'test':'test'

      
      showTopBar: ->
        @views.topBar.render().open()

      home: ->
        @clearViews()
        #@views.layout = new App.Layout.Main
        #@views.layout.render().open()

      test: ->
        @clearViews()
        window.v = new UI.MediaScrubber {
          min: 0
          max: 10000
        }
        v.render().open()
        v.on 'change', (val)-> console.log "change: #{val}"

      profile: ->
        @views.profile.render()

      files: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'files'
        @views.filez.render().open()

      fileDetail: (id)->
        @clearViews 'topBar'
        @views.fileDetail = new App.File.Views.Detail { model: @data.filez.get(id) }
        @views.fileDetail.render().open()

      students: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'students'
        @views.students.render().open()

      studentDetail: (id)->
        @clearViews 'topBar'
        @views.studentDetail?.remove()
        @views.studentDetail = new App.Student.Views.Detail { model: @data.students.get(id) }
        @views.studentDetail.render().open()

      studentRecording: (studentId,fileId)->
        @studentDetail(studentId)
        file = @data.filez.get(fileId)
        @views.studentDetail.loadFile(file)

      lab: ->
        @clearViews ['topBar','lab']
        @views.topBar.updateNav 'lab'
        
        @views.lab.open()  

      lounge: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'lounge'
        @views.lounge.render().open()

      stacks: ->
        @clearViews 'topBar'
        @views.topBar.updateNav 'stacks'

  [exports.Model,exports.Router] = [Model,Router]


$ ->

  window.app = new App.Model

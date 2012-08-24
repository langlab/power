module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: (attrs, options)->

      _.extend @, options

      @set {
        'settings': new UIState 
        'whiteBoardA': new UIState { visible: false }
        'whiteBoardB': new UIState
        'mediaA': new UIState
        'mediaB': new UIState
        'recorder': new UIState { state: 'clean-slate' }
        'questions': new UIState { visible: false }
        'recordings': new StudentRecordings
      }

      @attributes.teacherId = @teacher.id
      @setState @teacher.get('labState')

      # limit update of full labState to every 5 seconds
      throttledUpdate = _.throttle @updateState, 5000

      @students.on 'change:online', =>
        #@remoteAction 'all', 'update', @

      @get('whiteBoardA').on 'change', =>
        log 'change wba'
        @remoteAction 'whiteBoardA', 'update', @get('whiteBoardA').toJSON()
        throttledUpdate()

      @get('whiteBoardB').on 'change', =>
        @remoteAction 'whiteBoardB', 'update', @get('whiteBoardB').toJSON()
        throttledUpdate()

      @get('mediaA').on 'change', =>
        @remoteAction 'mediaA', 'update', @get('mediaA').toJSON()
        throttledUpdate()

      @get('mediaB').on 'change', =>
        @remoteAction 'mediaB', 'update', @get('mediaB').toJSON()
        throttledUpdate()

      @get('recorder').on 'change', =>
        log 'recorder:change'
        @remoteAction 'recorder', 'update', @get('recorder').toJSON()
        throttledUpdate()

      @get('settings').on 'change', =>
        @remoteAction 'settings', 'update', @get('settings').toJSON()
        throttledUpdate()


    fromDB: (data)->
      {method,model,options} = data
      {student}  = options
      @students.get(student._id).trigger 'recorder:state', model.recorder
    
    # sets the entire labState from nested JSON data
    setState: (data)->
      for area,state of data
        log 'setstate',area,state
        @get(area).set state


    addStudent: (studentId)->
      @sync 'add:student', null, {
        studentIds: [studentId]
        success: (data)=>
          log 'student added: ',data
      }

    removeStudent: (studentId)->
      @sync 'remove:student', null, {
        studentIds: [studentId]
        success: (data)=>
          log 'student removed', data
      }

    getStudents: ->
      @sync 'read:students', null, {
        success: (data)=>
          log 'students: ',data
      }

    # retrieve the state as nested JSON data snapshot
    getState: ->
      labState = {}

      for area, state of @attributes
        labState[area] = state.attributes

      labState

    # save the entire labState to the DB
    updateState: =>
      @sync 'update:state', @getState(), {
        success: (err,data)=>
          log 'state updated: ',data
      }

    remoteAction: (area, action, data)->
      
      actionObj =
        action: action
 
      actionObj[area] = data

      @sync 'action', actionObj, {
        success: (err,data)=>
          log 'action complete: ',data
      }

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'


  class StudentRecording extends Backbone.Model


  class StudentRecordings extends Backbone.Collection
    model: StudentRecording


  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.Recording extends Backbone.View
    tagName: 'tr'
    className: 'recording'

    template: ->
      td class:'recording-index', "#{ 1 + @model.collection.indexOf @model }"
      td class:"dur icon-#{ if @recorder.get('state') is 'stopped-recording' then 'play' else 'ok'} ", " #{ moment.duration(@model.get('duration')).seconds() }s"

    render: ->
      @$el.html ck.render @template, @options
      @

  class Views.StudentUpload extends Backbone.View
    tagName: 'tr'
    className: 'student-upload'

    template: ->
      student = app.data.students.get(@get('student'))
      td -> i class:'icon-comment'
      td -> "#{ student.get('name') }"



  class Views.Recorder extends Backbone.View
    tagName: 'div'
    className: 'recorder'

    initialize: (@options)->
      @recTimer = new App.Activity.Timer
      @playTimer = new App.Activity.Timer
      @bigRecTimer = new App.Activity.Timer
      @waitTimer = new App.Activity.Timer
      @setTimerEvents()
      @setStateEvents()

      @collection.on 'change', => @renderRecordings()
      @collection.on 'reset', => @renderRecordings()

      @model.on 'change:recordings', =>
        if @model.get('state') is 'submitting' then @renderControls()

      @options.filez.on 'add', (file)=>
        @renderUploads()

    setTimerEvents: ->

      @playTimer.on 'tick', (data)=>
        {ticks,secs} = data
        

      @playTimer.on 'seek', (data)=>
        {ticks,secs} = data
        

      @recTimer.on 'tick', (data)=>
        {ticks,secs} = data

        if @model.get('state') is 'recording-duration'
          timeLeft = moment.duration(@model.get('duration') - ticks)
          secsLeft = (Math.floor timeLeft.seconds()) + 1
          minsLeft = Math.floor timeLeft.minutes()
          
          waitText = "recording, pauses in#{ if minsLeft then ' '+minsLeft+'m' else '' } #{ secsLeft }s"
          @$('.time-left-recording').text waitText

      @waitTimer.on 'tick', (data)=>
        {ticks,secs} = data
        timeLeft = moment.duration(@model.get('delay') - ticks)
        secsLeft = (Math.floor timeLeft.seconds()) + 1
        minsLeft = Math.floor timeLeft.minutes()
        
        waitText = "recording in#{ if minsLeft then ' '+minsLeft+'m' else '' } #{ secsLeft }s"
        @$('.time-until-record').text waitText

    setStateEvents: ->
      @model.on 'change:state', (m,state)=>
        console.log state
        @renderControls()

        switch state

          when 'recording'
            @recTimer.start()
            @bigRecTimer.start()

          when 'waiting-to-record'
            @waitTimer.start()

          when 'recording-duration'
            @waitTimer.stop()
            @recTimer.start()
            @bigRecTimer.start()

          when 'paused-recording'
            @collection.add {
              at: @bigRecTimer.currentMSecs() - @recTimer.currentMSecs()
              delay: @model.get('delay')
              duration: @recTimer.currentMSecs()
            }
            @recTimer.stop()
            @bigRecTimer.pause()
            @renderRecordings()

          when 'stopped-recording'
            @recTimer.stop()
            @bigRecTimer.stop()
            @renderRecordings()

          when 'playing'
            @playTimer.start()

          when 'paused-playing'
            @playTimer.pause()

          when 'stopped-playing'
            @playTimer.stop()

          when 'clean-slate'
            @recTimer.stop()
            @playTimer.stop()
            @bigRecTimer.stop()
            @collection.reset()
            log 'resetting lastSubmit'
            @model.set {
              lastSubmit: null
            }
            @renderUploads()

          when 'submitting'
            @collection.reset()


    events:
      'click .start-record': (e)->
        e.preventDefault()
        @startRecordingIn $(e.currentTarget).attr('data-delay'), $(e.currentTarget).attr('data-duration')
        #@model.set 'state', 'recording'
      'click .pause-record': ->
        @model.set 'state', 'paused-recording'
      'click .stop-record': ->
        @model.set 'state', 'stopped-recording'
      'click .start-play': ->
        @model.set 'state', 'playing'
      'click .pause-play': ->
        @model.set 'state', 'paused-playing'
      'click .submit-rec': ->
        @model.set {
          state: 'submitting'
          lastSubmit: moment().valueOf()
          tags: @options.settings.get('tags')
        }
        @model.set 'state', 'waiting-for-recordings'
      'click .trash-rec': ->
        @model.set 'state', 'clean-slate'
        @model.set 'recStart', 0
        @model.set 'recStop', 0

      

    controlsTemplate: ->
      switch (state = @model.get('state'))

        when 'clean-slate', 'paused-recording'
          div class:'btn-group', ->
            button class:'btn btn-small btn-danger icon-certificate start-record','data-delay':0, 'data-duration':0, " record"
            button class:'btn btn-small btn-danger dropdown-toggle', 'data-toggle':'dropdown', ->
              span class:'caret'
            ul class:'dropdown-menu', ->
              li -> a href:'#', class:'start-record','data-delay':5, 'data-duration':10, 'in 5s, for 10s'
              li -> a href:'#', class:'start-record','data-delay':10, 'data-duration':30, 'in 10s, for 30s'
              li -> a href:'#', class:'start-record','data-delay':15, 'data-duration':60, 'in 15s, for 1min'
              li -> a href:'#', class:'start-record','data-delay':20, 'data-duration':90, 'in 20s, for 1&frac12min'
              li -> a href:'#', class:'start-record','data-delay':30, 'data-duration':120, 'in 30s, for 2min'
              li -> a href:'#', class:'start-record','data-delay':60, 'data-duration':180, 'in 1min, for 3min'
              li -> a href:'#', class:'start-record','data-delay':60, 'data-duration':240, 'in 1min, for 4min'

            if state is 'paused-recording'
              button class:'btn btn-mini btn-inverse icon-sign-blank stop-record', ' fin'

        when 'waiting-to-record'
          div class:'time-until-record', 'waiting to record'
        
        when 'recording-duration'
          div class:'time-left-recording', 'recording for duration'

        when 'recording'
          div class:'time-recorded', 'recording'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-danger icon-pause pause-record', ' pause'

        when 'stopped-recording','paused-playing', 'stopped-playing', 'playing'
          div class:'time-played'
          div class:'btn-toolbar', ->
            div class:'btn-group', ->
              button class:"btn btn-mini btn-info #{ if state is 'playing' then 'icon-pause start-pause' else 'icon-play pause-play' }", ' play all'
            div class:'btn-group', ->
              button class:'btn btn-mini btn-success icon-download-alt submit-rec', ' save as'
            div class:'btn-group pull-right', ->
              button class:'btn btn-mini btn-danger icon-trash trash-rec', 

        when 'submitting'
          log 'submitting...'

        when 'waiting-for-recordings'
          div class:'waiting-for-recordings', ->
            if @model.get('recordings')
              text "#{@model.get('student-recordings')} received"
            else
              text "waiting on recordings..."
        
      div class:'btn-toolbar', ->


    renderControls: ->
      @$('.controls-cont').html ck.render @controlsTemplate, @options
      @



    formattedTime: (time)->
      mins = time.mins
      secs = if time.secs < 10 then "0#{time.secs}" else time.secs
      "#{mins}:#{secs}"


    updateTimeRecorded: ->
      log 'time-rec'
      @$('.time-recorded').text @formattedTime @recTimer.currentTimeObj()

    updateTimePlayed: ->
      @$('.time-played').text @formattedTime @playTimer.currentTimeObj()

    pauseRecording: ->
      @model.set 'state', 'paused-recording'

    recordFor: (duration)=>
      if duration

        @recTimer.stop()
        @recTimer.addCues { at: duration, fn: => @pauseRecording() }
        @model.set {
          'state': 'recording-duration'
          'duration': duration*1000
        }

        
      else
        @model.set 'state', 'recording'
      
    startRecordingIn: (delay,duration)=>
      if delay

        @waitTimer.stop()
        @waitTimer.addCues { at: delay, fn: => @recordFor duration }
        @model.set {  
          'state': 'waiting-to-record'
          'delay': delay*1000
        }
        
      else
        @recordFor duration

    renderRecordings: ->
      @$('.student-recordings').empty()
      for rec in @collection.models
        rv = new Views.Recording { model: rec, recorder: @model }
        rv.render().open @$('.student-recordings')

    renderUploads: ->
      @$('.student-uploads').empty()
      for upl in @options.filez.recUploads(@model.get('lastSubmit'))
        uv = new Views.StudentUpload { model: upl }
        uv.render().open @$('.student-uploads')
    
    template: ->
      div class:'accordion-group', ->
        div class:'accordion-heading ', ->
          span class:'accordion-toggle icon-comment', 'data-toggle':'collapse', 'data-target':'.lab-recorder', ' Recorder'
          
        div class:'collapse in lab-recorder accordion-body', ->
          div class:'accordion-inner', ->
            div class:'recorder-cont', ->
              div class:'time-played', ->
              div class:'scrubber-cont', ->

              div class:'controls-cont', ->

              table class:'table table-condensed table-hover student-recordings', ->

              table class:'table table-condensed table-hover student-uploads', ->
      


    render: ->
      @$el.html ck.render @template, @options
      @renderControls()
      @renderRecordings()
      @renderUploads()
      @

  class Views.MediaPlayer extends Backbone.View
    tagName:'div'
    className: 'media-player'

    playbackRates: [0.5,0.75,1,1.25,1.5,2]

    rateLabel: (val)->
      switch val
        when 0.5 then '&frac12;x'
        when 0.75 then '&frac34;x'
        when 1 then '1x'
        when 1.25 then '1&frac14;x'
        when 1.5 then '1&frac12;x'
        when 2 then '2x'


    initialize: (@options)->

      @collection.on "load:#{@options.label}", (file)=>
        @model.set 'file', file.attributes
        @model.trigger 'change:file', @model, @model.get('file') 
          #because changing object internals doesn't trigger a change

        @render()
        @setPcEvents()

      @on 'open', =>
        @setPcEvents()

      @model.on 'change:visible', =>
        @$('.accordion-group').toggleClass('visible')
        @$('.toggle-visible').toggleClass('icon-eye-open').toggleClass('icon-eye-close')

        
      @model.on 'change:muted', (m,muted)=>
        @$('.toggle-mute').toggleClass('icon-volume-up').toggleClass('icon-volume-off')
        @pc.volume (if muted then 0.1 else 1)


        


    events:
      'click .change-media': 'selectMedia'
      'click .speed-option':'changeSpeed'
      'click .play': -> @pc.play()
      'click .pause': -> @pc.pause()
      'click .back-10': -> @pc.currentTime @pc.currentTime()-10
      'click .back-5': -> @pc.currentTime @pc.currentTime()-5
      
      'click .toggle-mute': -> 
        console.log 'vol',@pc.volume()
        @model.set 'muted', not @model.get('muted')
        
      'click .toggle-visible': (e)->
        e.stopPropagation()
        @model.set 'visible', not @model.get('visible')

      'click .speed-inc': -> @changeSpeed 1
      'click .speed-dec': -> @changeSpeed -1

        

    template: ->
      file = @model.get('file')
      div class:"accordion-group#{if @model.get('visible') then ' visible' else ''}", ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle ', ->
            span 'data-toggle':'collapse', 'data-target':".lab-media-#{@label}", class:"media-name icon-facetime-video", " #{file?.title ? 'Media...'}" 
            span class:'pull-right', ->
              if file?.type in ['audio','video']
                button class:"btn btn-mini icon-cogs"
                
              if file?
                text "&nbsp;&nbsp;"
                button class:'btn btn-mini change-media icon-remove'
              else
                form class:'navbar-search pull-right', ->
                  input type:'text', class:'search-query input-small', placeholder: 'search'
                

        div class:"collapse in lab-media-#{@label} accordion-body", ->
          div class:'accordion-inner', ->
            if file?
              div class:'controls-cont', ->
              div class:'scrubber-cont', ->
              div class:'media-cont', ->
            else
              div class:'lab-file-list', ->
                table class:'table table-condensed table-hover', ->
                  tbody ->

    selectMedia: (e)->
      e.stopPropagation()
      @model.set 'file', null
      @model.set 'visible', false
      @model.set 'currentTime', 0
      @render()

    changeSpeed: (amt)->
      i = _.indexOf @playbackRates, @pc.playbackRate()
      i = if (i+amt is @playbackRates.length) or (i+amt < 0) then i else i + amt
      
      @pc.playbackRate @playbackRates[i]

    formattedTime: ->
      totalSecs = Math.floor(@pc.currentTime())
      min = Math.floor (totalSecs / 60)
      secs = totalSecs % 60 
      "#{min}:#{secs}"


    controlsTemplate: ->
      div class:'btn-toolbar span12', ->      
        if (type = @model.get('file').type) is 'image'
          div class:"btn-group pull-right", ->
            button class:"btn btn-mini pull-left icon-eye-#{ if @model.get('visible') then 'open' else 'close' } toggle-visible"
        else if type in ['audio','video']

          div class:'btn-group pull-left', ->
            button class:"btn btn-mini#{ if @pc.playbackRate() is 0.5 then ' disabled' else '' } icon-caret-left speed-dec"
            button class:'btn btn-mini disabled speed', " #{ @rateLabel @pc.playbackRate() } speed"
            button class:"btn btn-mini#{ if @pc.playbackRate() is 2 then ' disabled' else '' } icon-caret-right speed-inc"

          div class:'btn-group', ->
            span class:'time', "#{@formattedTime()}"

          div class:'btn-group', ->
            button class:"btn btn-mini pull-left icon-eye-#{ if @model.get('visible') then 'open' else 'close' } toggle-visible"
            button class:"btn btn-mini icon-volume-#{ if @model.get('muted') then 'off' else 'up' } pull-left toggle-mute"


          div class:'btn-group pull-right', ->
            if @pc.paused()
              div class:'btn btn-mini btn-success icon-play play', " play"
            else
              div class:'btn btn-mini icon-pause pause', " pause"

          #div class:'btn-group pull-right', ->
            #div class:'btn btn-mini icon-fast-backward back-10', " 10s"
            #div class:'btn btn-mini icon-step-backward back-5', " 5s"

    avTemplate: ->
      video class:"#{ @file.type }-type", ->
        if @file.type is 'video'
          source src:"#{@file.webmUrl}"
          source src:"#{@file.h264Url}"
        if @file.type is 'audio'
          source src:"#{@file.mp3Url}"
      

    renderControls: ->
      console.log 'render cntrols'
      @$('.controls-cont').html ck.render @controlsTemplate, @
      @

    renderScrubber: ->
      @scrubber.render().open @$('.scrubber-cont')
      @scrubber.on 'change', (v)=>
        console.log 'change scrubber', v
        @pc.currentTime v/1000

    setPcEvents: ->
      console.log 'ev'
      if @model.get('file')?.type in ['video','audio']
        @pc = new Popcorn @$('.media-cont video')[0]


        @pc.on 'canplay', =>
          @renderControls()
          @pc.currentTime @model.get('currentTime')
          @pc.playbackRate @model.get('playbackRate')
          @scrubber = new UI.Slider { max: @pc.duration() * 1000 }
          @renderScrubber()

        @pc.on 'playing', => 
          @model.set { currentTime: @pc.currentTime() }, { silent: true }
          @model.set 'state', 'playing'
          @renderControls()

        @pc.on 'pause', => 
          @model.set { currentTime: @pc.currentTime() }, { silent: true }
          @model.set 'state', 'paused'
          @renderControls()

        @pc.on 'ended', =>
          @model.set 'event', 'ended'
          @renderScrubber()

        @pc.on 'seeking', =>
          @model.set {
            currentTime: @pc.currentTime()
            event: 'seeking'
          }

        @pc.on 'ratechange', =>
          console.log 'rate change'
          @model.set 'playbackRate', @pc.playbackRate()
          @renderControls()

        @pc.on 'timeupdate', =>

          @model.set {
            currentTime: @pc.currentTime()
          }, { silent: true }

          @scrubber.setVal(@pc.currentTime() * 1000)
          @$('.time').text @formattedTime()

    render: ->
      file = @model.get 'file'
      @$el.html ck.render @template, @options
      if not file?
        for file in @collection.models
          fv = new Views.LabFile { model: file, label: @options.label }
          fv.render().open @$('.lab-file-list tbody') 
      else
        switch file.type
          when 'image'
            imgEl = $('<img/>').attr('src',file.imageUrl)
            imgEl.appendTo @$('.media-cont')
            @renderControls()
          when 'video','audio'
            @$('.media-cont').html ck.render @avTemplate, @model.attributes
      @

  class Views.LabStudent extends Backbone.View
    tagName: 'tr'
    className: 'lab-student'

    recorderStates:
      'submitting':'rss'
      'submitted':'download-alt'
      'none':''
      'recording':'comment'
      'recording-duration':'comment'


    initialize: ->
      @model.on 'change:online', (student,online)=>
        @$el.toggleClass 'online', online
        @model.collection.trigger 'change:online', @model

      @model.on 'change:help', (student,help)=>
        @$el.toggleClass 'help', help
        @render()
        #@model.collection.trigger 'help'
        #if help then @sfx('sos')

      @model.on 'recorder:state', (recorder)=>
        @$('.recorder-state i').removeClass().addClass("icon-#{@recorderStates[recorder.state]}")


    events:
      'click .toggle-control': ->
        @model.toggleControl()
        @model.collection.trigger 'change:control'

    template: ->
      recorderState = @model.get('teacherLabState')?.recorder.state ? 'none'
      log 'recstate:',recorderState
      td -> button 'data-id':"#{@model.id}", class:"btn btn-mini icon-hand-up box toggle-control #{if @model.get('control') then 'active' else ''}", 'data-toggle':'button'
      td -> i class:"online-status icon-#{if @model.get 'help' then 'bullhorn' else 'heart' } #{if @model.get 'online' then 'online' else ''}#{if @model.get 'help' then ' help' else '' }"
      td class:'recorder-state', -> i class:"icon-#{ @recorderStates[recorderState] }"
      td "#{@model.get 'name'}"

    render: ->
      @$el.html ck.render @template, @
      @$el.toggleClass 'help', @model.get('help')
      @$el.toggleClass 'online', @model.get('online')
      @


  class Views.LabFile extends Backbone.View
    tagName: 'tr'
    className: 'lab-file'

    initialize: (@options)->

    events:
      'click': -> @model.collection.trigger "load:#{@options.label}", @model

    template: ->
      td ->
        img src:"#{@thumbnail()}"
      td ->
        div "#{@get 'title'}"

  class Views.WhiteBoard extends Backbone.View
    tagName: 'div'
    className: 'lab-whiteboard'

    initialize: (@options)->
      @editor = new UI.HtmlEditor { html: @model.get 'html' }

      ###
      @on 'open', =>
        @editor.open @$('.wb-cont')
      ### 

      @model.on 'change:visible', =>
        @$('.accordion-group').toggleClass('visible')
        @$('.toggle-visible').toggleClass('icon-eye-close').toggleClass('icon-eye-open')
        @$('.editor-area').toggleClass('visible')

    events:
      'keyup .editor-area':'update'
      'click button, a':'update'
      'click .accordion-group': -> @model.set 'open', not @model.get('open')
      'click .toggle-visible': (e)->
        e.stopPropagation()
        @model.set 'visible', not @model.get('visible')


    update: ->
      @model.set 'html', @editor.simplifiedHTML()
        
    template: ->
      div class:"accordion-group #{if @model.get('visible') then 'visible' else ''}", ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle icon-edit', 'data-toggle':'collapse', 'data-target':".lab-wb-#{ @label }", ->
            text " Whiteboard #{ @label }"
            span class:'btn-group pull-right', ->
              
        div class:"collapse#{ if @model.get('open') then ' in' else '' } lab-wb-#{ @label } accordion-body", ->
          div class:'accordion-inner wb-cont', ->
            div class:"wb-cont-#{ @label }", ->

    eyeTemplate: ->
      button class:"btn btn-mini icon-eye-#{ if @model?.get('visible') then 'open' else 'close' } toggle-visible"

    render: ->
      @$el.html ck.render @template, @options
      @editor.render().open @$(".wb-cont-#{@options.label}")
      @$('.wb-header .right-group').html ck.render @eyeTemplate, @options
      @$('.editor-area').toggleClass 'visible', @model.get 'visible'
      @


  class Views.Questions extends Backbone.View
    tagName: 'div'
    className: 'lab-questions-main'

    initialize: (@options)->

    template: ->
      div class:"accordion-group #{if @model.get('visible') then 'visible' else ''}", ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle icon-edit', 'data-toggle':'collapse', 'data-target':".lab-questions", ->
            text " Questions"
            span class:'btn-group pull-right', ->
              
        div class:"collapse#{ if @model.get('open') then ' in' else '' } lab-questions accordion-body", ->
          div class:'accordion-inner questions-cont', ->
            text "blarg"

    render: ->
      @$el.html ck.render @template, @options
      @

  class Views.Students extends Backbone.View

    initialize: (options)->
      @collection.on 'help', =>
        @renderHeading()

      @collection.on 'change:control', @render, @

    headingTemplate: ->
      span class:'accordion-toggle icon-group', 'data-toggle':'collapse', 'data-target':'.lab-students', ->
        span class:'', ' Students'
        span class:'pull-right', ->
          if (needHelp = @collection.studentsNeedingHelp())
            span class:'icon-bullhorn need-help', " #{needHelp}"

    template: ->
      div class:'accordion-group', ->
        div class:'accordion-heading ', ->
          #heading template goes here
        div class:'collapse in lab-students accordion-body', ->
          div class:'accordion-inner', ->
            table class:'table table-condensed table-hover lab-student-list', ->
              tbody class:'control'
              tbody class:'no-control'
            
            

    renderHeading: ->
      @$('.accordion-heading').html ck.render @headingTemplate, @options
      @

    renderStudentsList: ->

      for stu in @collection.controlled()
        sv = new Views.LabStudent { model: stu }
        sv.render().open @$('.lab-student-list tbody.control')

      for stu in @collection.notControlled()
        sv = new Views.LabStudent { model: stu }
        sv.render().open @$('.lab-student-list tbody.no-control')

    render: ->
      @$el.html ck.render @template, @options
      @renderHeading()
      @renderStudentsList()
      @

  class Views.Settings extends Backbone.View

    tagName: 'div'
    className: 'lab-setting-main'

    initialize: (@options)->
      console.log @model.get('tags')
      @tags = new UI.Tags { 
        tags: @model.get 'tags' 
        typeahead: top.app.tagList()
      }

      @tags.on 'change', (arr,str)=>
        console.log str
        @model.set 'tags', str

    template: ->
      div class:'accordion-group', ->
        div class:'accordion-heading ', ->
          span class:'accordion-toggle icon-wrench', 'data-toggle':'collapse', 'data-target':'.lab-settings', ' Lab Settings'
        div class:'collapse in lab-settings accordion-body', ->
          div class:'accordion-inner', ->
            form class:'form-inline',->
              label "Enter some tags that you want attached to student submissions:"
              div class:'act-tags-cont', ->


    render: ->
      @$el.html ck.render @template, @options
      @tags.render().open @$('.act-tags-cont')
      @

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: (@options)->
      
      @wbA = new Views.WhiteBoard { label: 'A', model: @model.get('whiteBoardA') }
      @wbB = new Views.WhiteBoard { label: 'B', model: @model.get('whiteBoardB') }
      
      @recorder = new Views.Recorder { 
        model: @model.get('recorder')
        collection: @model.get('recordings')
        filez: @model.filez
        students: @model.students
        settings: @model.get('settings') 
      }
      
      @mediaA = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaA'), label: 'A' }
      @mediaB = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaB'), label: 'B' }

      @questions = new Views.Questions { model: @model.get('questions') }

      @settings = new Views.Settings { model: @model.get('settings') }

      @students = new Views.Students { collection: @model.students }

      @recorder.model.on 'change:state', (model, state)=>
        console.log 'recorder change: ',state
        if state in ['recording','waiting-to-record']
          @mediaA.pc?.pause()
          @mediaB.pc?.pause()
        if state is 'paused-recording'
          @mediaA.pc?.play()
          @mediaB.pc?.play()

      


    events:
      
      'click [data-toggle=collapse]': (e)->
        $(e.currentTarget).parent('.accordion-group').toggleClass('open')


    template: ->
      #div class:'container-fluid', ->

      
      # the Files/Students Sidebar
      div class:'row-fluid', ->
        
        div class:'span3', ->

          div class:'lab-settings-cont', ->

          div class:'lab-recorder-cont', ->
            
            

          div class:'lab-students-cont', ->
            

        div class:'span4', ->

          # Media A
          div class:'lab-media-a-cont', ->

          # Media B
          div class:'lab-media-b-cont', ->


        div class:'span5 content', ->

          

          # Whiteboard A
          div class:'lab-whiteboard-a-cont', ->  
          
          # Whiteboard B
          div class:'lab-whiteboard-b-cont', ->

          div class:'lab-questions-cont', ->



    render: ->
      @$el.html ck.render @template, @options
      

      @mediaA.render().open @$('.lab-media-a-cont')
      @mediaB.render().open @$('.lab-media-b-cont')

      @wbA.render().open @$('.lab-whiteboard-a-cont')
      @wbB.render().open @$('.lab-whiteboard-b-cont')

      @recorder.render().open @$('.lab-recorder-cont')
      @settings.render().open @$('.lab-settings-cont')

      @students.render().open @$('.lab-students-cont')

      @questions.render().open @$('.lab-questions-cont')

      @




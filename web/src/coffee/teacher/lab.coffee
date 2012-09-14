module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: (attrs, options)->

      _.extend @, options

      @set {
        'settings': new UIState
        'timeline': new Timeline
        'whiteBoardBig': new UIState { visible: false }
        'whiteBoardA': new UIState { visible: false }
        'whiteBoardB': new UIState { visible: false }
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

      @get('whiteBoardBig').on 'change', =>
        log 'change wbBig'
        @remoteAction 'whiteBoardBig', 'update', @get('whiteBoardBig').toJSON()
        throttledUpdate()

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

  class Timeline extends Backbone.Model
    initialize: ->
      @events = new Events

  class Event extends Backbone.Model

  class Events extends Backbone.Collection
    model: Event

    comparator: (m)->
      m.get('at')

  class StudentRecording extends Backbone.Model


  class StudentRecordings extends Backbone.Collection
    model: StudentRecording

    initialize: ->
      @on 'add', => @totalDuration = @reduce ((memo,rec)-> memo + rec.get('duration')), 0
      @on 'reset', => @totalDuration = 0


  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.Recording extends Backbone.View
    tagName: 'tr'
    className: 'recording'

    template: ->
      td class:'recording-index', "#{ 1 + @model.collection.indexOf @model }"
      td class:"dur icon-#{ if @recorder.get('state') is 'stopped-recording' then 'play' else 'ok'} ", " #{ moment.duration(@model.get('duration')).asSeconds() }s"

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

      @collection.on 'add', => @renderRecordings()
      @collection.on 'reset', => @renderRecordings()


      @options.filez.on 'add', (file)=>
        @renderUploads()


    setTimerEvents: ->

      @playTimer.on 'tick', (data)=>
        {ticks,secs} = data
        @$('.pause-play').text " #{@playTimer.formattedCurrentTime()}"
        

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
              question: @model.get('question')
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
            console.log @collection.totalDuration
            @playTimer.addCues {
              at: @collection.totalDuration/1000
              fn: => 
                console.log 'stopping...'
                @model.set 'state','stopped-playing'
            }

            @playTimer.start()

          when 'paused-playing'
            @playTimer.pause()

          when 'stopped-playing'
            @playTimer.stop()

          when 'clean-slate'
            @recTimer.stop()
            @playTimer.stop()
            @bigRecTimer.stop()
            @collection.reset []
            log 'resetting lastSubmit'
            @model.set {
              lastSubmit: null
            }

          when 'submitting'
            console?.log 'submitting...'
        @renderControls()
        @renderUploads()
            


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
          title: @options.settings.get('title')
        }
        @model.set 'state', 'waiting-for-recordings'

      'click .clean-slate': ->
        @model.set 'state', 'clean-slate'

      'click .trash-rec': ->
        @model.set 'state', 'clean-slate'
        @model.set 'recStart', 0
        @model.set 'recStop', 0

      'change .question-label': (e)->
        @model.set 'question', $(e.currentTarget).val()

      'click .pause-on-record': (e)->
        $(e.currentTarget).toggleClass('active')
        @model.set 'pauseMediaOnRecord', not @model.get 'pauseMediaOnRecord'

      'click .student-control': (e)->
        $(e.currentTarget).toggleClass('active')
        @model.set 'studentControl', not @model.get 'studentControl'
      

    controlsTemplate: ->
      
      div class:'btn-toolbar', ->
        div class:'btn-group', ->
          #button rel:'tooltip', title:'', class:"btn btn-mini icon-eye-#{if @model.get('controlVisible') then 'open active' else 'close'}"
          button rel:'tooltip', title:'Give student control of the recorder', class:"btn btn-mini student-control icon-hand-up #{if @model.get('studentControl') then 'active' else ''}"
          button rel:'tooltip', title:'Automatically pause media while recording.', class:"btn btn-mini icon-film pause-on-record #{if @model.get('pauseMediaOnRecord') then 'active' else ''}"

      switch (state = @model.get('state'))

        when 'clean-slate', 'paused-recording'
          input type:'text', placeholder:"What is question ##{@collection.length+1}", class:'span12 question-label pull-left' 
          #div class:"icon-check#{if @model.get('pauseMediaOnRecord') then '' else '-empty'} pause-on-record", " pause media while recording"
          div class:'btn-toolbar', ->
            div class:'btn-group', ->
              button class:'btn btn-mini btn-danger icon-certificate start-record','data-delay':0, 'data-duration':0, " record now"
            div class:'btn-group', ->
              button class:'btn btn-mini btn-danger dropdown-toggle icon-time', 'data-toggle':'dropdown', ->
                span " rec "
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
          div class:'alert alert-info time-until-record', 'waiting to record'
        
        when 'recording-duration'
          div class:'alert alert-danger time-left-recording', 'recording for duration'

        when 'recording'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-inverse icon-pause pause-record btn-block', ' pause'

        when 'stopped-recording','paused-playing', 'stopped-playing'
          div class:'btn-toolbar', ->
            div class:'btn-group', ->
              button class:"btn btn-mini btn-success icon-play start-play", ' 0:00'
            div class:'btn-group', ->
              button class:'btn btn-mini btn-info icon-download-alt submit-rec', ' collect'
            div class:'btn-group pull-right', ->
              button class:'btn btn-mini btn-danger icon-trash trash-rec', ' discard'

        when 'playing'
          div class:'btn-group', ->
            button class:"btn btn-mini btn-inverse icon-pause pause-play", ' play all'

        when 'submitting'
          log 'submitting...'

        when 'waiting-for-recordings'
          div class:'waiting-for-recordings', ->

        
      div class:'btn-toolbar', ->


    renderControls: ->
      @$('.controls-cont').html ck.render @controlsTemplate, @options
      @$('[rel=tooltip]').tooltip()
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
      if @collection.length
        @$('.student-recordings').html("#{@collection.length} responses so far")
      for rec in @collection.models
        rv = new Views.Recording { model: rec, recorder: @model }
        rv.render().open @$('.student-recordings')

    uploadTemplate: ->
      uploads = @filez.recUploads(@model.get('lastSubmit'))
      if uploads.length is @students.onlineControlled().length
        if uploads.length > 1
          div class:"alert alert-succes icon-ok", " All #{uploads.length} recordings received!"
        else
          div class:"alert alert-succes icon-ok", " Recording received!"
        button class:"btn btn-success clean-slate", " record again"
      else
        div class:"alert alert-warning icon-ok", " #{uploads.length} recording#{if uploads.length > 1 then 's' else ''} received so far"
        button class:"btn btn-warning clean-slate", " record again"

    renderUploads: ->
      if @model.get('state') is 'waiting-for-recordings'
        @$('.student-uploads').html ck.render @uploadTemplate, @options
        uploads = @options.filez.recUploads(@model.get('lastSubmit'))
      else
        @$('.student-uploads').empty()
    
    template: ->
      
      div class:'accordion-group', ->
        div class:'accordion-heading ', ->
          span class:'accordion-toggle icon-comment', 'data-toggle':'collapse', 'data-target':'.lab-recorder', ' Recorder'
          
        div class:'collapse lab-recorder accordion-body', ->
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


  class Views.Event extends Backbone.View
    tagName: 'tr'
    className: 'event-view'

    events:
      'click .delete': ->
        @model.collection.remove @model

    formatTime: (ms)->
      secs = if (s = moment.duration(ms).seconds()) < 10 then "0#{s}" else s
      mins = moment.duration(ms).minutes()
      "#{mins}:#{secs}"

    formatDur: (ms)->
      ms = parseInt(ms,10)
      secs = "#{moment.duration(ms).seconds()}s"
      mins = if (m=moment.duration(ms).minutes()) then "#{m}m" else ''
      "#{mins} #{secs}"

    template: ->
      td "at #{@formatTime @model.get('at')}"
      td -> span class:"#{if @model.get('pauseMedia') then 'icon-pause' else ''}", "#{if @model.get('pauseMedia') then 'media' else ''}"
      td "wait #{@formatDur(@model.get('delay'))}..."
      td "record for #{@formatDur @model.get('duration')}"
      td "save as '#{@model.get('question')}'"
      td -> button class:'btn btn-danger btn-mini icon-trash delete'

    render: ->
      @$el.html ck.render @template, @
      @


  class Views.Timeline extends Backbone.View
    tagName: 'div'
    className: 'modal fade hide events-timeline'

    delayTimes: [5,10,15,20,30,60,75,90,120,180]
    recordTimes: [10,15,20,30,60,75,90,120,180,240]

    initialize: (@options)->

      @lab = @options.lab
      @media = @options.media
      @mediaFile = new App.File.Model @media.get('file')
      @mediaPlayer = new UIState { state: 'paused' }

      @model.events.on 'add', =>
        @renderEvents()

      @model.events.on 'remove', =>
        console.log 'removed'
        @renderEvents()

      @media.on 'change:file', (m,file)=>
        @mediaFile = new App.File.Model @media.get('file')

      @on 'open', =>
        @$el.modal 'show'

        @$el.on 'hidden', =>
          @remove()

      @mediaPlayer.on 'change:state', (m,state)=>
        switch state
          when 'playing'
            @pc.play()
          when 'paused'
            @pc.pause()

    events:
      'click .play': -> @mediaPlayer.set 'state', 'playing'
      'click .pause': -> @mediaPlayer.set 'state', 'paused'

      'click [data-delay]': (e)->
        e.preventDefault()
        secs = $(e.currentTarget).attr('data-delay')
        @$('.delay-time').attr('data-delay-time', secs*1000 ).find('.time-label').text " wait for #{secs}s"

      'click [data-record]': (e)->
        e.preventDefault()
        secs = $(e.currentTarget).attr('data-record')
        @$('.record-time').attr('data-record-time', secs*1000 ).find('.time-label').text " record for #{secs}s"

      'click .add-event': 'addEvent'

      'click .pause-media': (e)->
        console.log 'check'
        $(e.currentTarget).toggleClass('icon-check-empty').toggleClass('icon-check')



    addEvent: (e)->
      eventData = {
        at: @pc.currentTime()*1000
        delay: @$('.delay-time').attr('data-delay-time')
        duration: @$('.record-time').attr('data-record-time')
        question: @$('.question').val()
        pauseMedia: @$('.pause-media').hasClass('icon-check')
      }
      @model.events.add eventData

    addEventView: (event)->
      v = new Views.Event { model: event }
      v.render().open @$('.events-cont')

    close: ->
      @model.set 'state', 'paused'
      @$el.modal 'hide'

    template: ->
      div class:'modal-header', ->
        h4 "Media Timeline for #{@lab.get('title')}"
      
      div class:'modal-body', ->
        div class:'row-fluid', ->
          span class:'play-btn-cont span1', ->
          span class:'scrubber-cont span10', ->
            input type:'range', min:0, max:100, step:1

        div class:'row-fluid', ->

          div class:'pull-right span9', ->
            
            ul class:'nav nav-tabs', ->
              li -> a href:'#tab-settings', 'data-toggle':'tab', ->
                i class:'icon-wrench'
                span " Settings"
              li class:'active', -> a href:'#tab-events', 'data-toggle':'tab',  ->
                i class:'icon-time'
                span " Recording Events"
              
            div class:'tab-content', ->
              div class:'tab-pane', id:'tab-settings', ->
                span "settings"
              div class:'tab-pane active', id:'tab-events', style:'min-height:200px', ->
                table class:'table table-condensed table-hover', ->
                  thead ->
                    tr ->
                      td ->
                        button class:'btn btn-mini current-time disabled', "0:00"
                      td ->
                        button class:'btn btn-mini icon-check pause-media', ->
                          span "&nbsp;"
                          span class:'icon-pause ', " media"
                      td ->
                        div class:'btn-group', ->
                          button class:'btn btn-mini btn-inverse dropdown-toggle icon-time delay-time', 'data-delay-time':'5000', 'data-toggle':'dropdown', ->
                            span class:'time-label', " wait for 5s "
                            span class:'caret' 
                          ul class:'dropdown-menu', ->
                            for delayTime in @delayTimes
                              li -> a href:'#', 'data-delay':delayTime, "#{moment.duration(delayTime*1000).asSeconds()}s"
                      td ->
                        div class:'btn-group', ->
                          button class:'btn btn-mini btn-danger dropdown-toggle icon-time record-time', 'data-record-time':'10000', 'data-toggle':'dropdown', ->
                            span class:'time-label', " record for 10s "
                            span class:'caret' 
                          ul class:'dropdown-menu', ->
                            for recordTime in @recordTimes
                              li -> a href:'#', 'data-record':recordTime, "#{moment.duration(recordTime*1000).asSeconds()}s"
                      td ->
                        input type:'text', placeholder:'What is the question?', class:'input-large question'
                      td ->
                        button class:'btn btn-mini btn-success icon-plus add-event', " add"
                  tbody class:'events-cont', ->
                    if not @model.events.length
                      tr -> td colspan:5, ->
                        div class:'alert alert-info', " There are no events yet." 


          div class:'pull-left span3', ->
            if @mediaFile.get('type') is 'video'
              video src:"#{@mediaFile.src()}", width:'90%'
            else if @mediaFile.get('type') is 'audio'
              audio src:"#{@mediaFile.src()}"
            

          


      div class:'modal-footer', ->
        button 'btn-success btn-small btn icon-ok', " Save"

    playButtonTemplate: ->
      if @mediaPlayer.get('state') is 'paused'
        button "btn btn-success btn-mini icon-play play play-pause", " #{@formattedTime()}"
      else
        button "btn btn-inverse btn-mini icon-pause pause play-pause", " #{@formattedTime()}"

    formattedTime: ->
      dur = moment.duration @pc.currentTime()*1000
      "#{dur.minutes()}:#{if (secs = dur.seconds()) < 10 then '0'+secs else secs}"

    setPcEvents: ->
      @pc?.destroy()
      @pc = new Popcorn @$("#{@mediaFile.get('type')}")[0]
      @pc.on 'canplay', =>
        @renderPlayButton()
      @pc.on 'play', =>
        @renderPlayButton()
      @pc.on 'pause', =>
        @renderPlayButton()
      @pc.on 'timeupdate', =>
        @$('.current-time').text " at #{@formattedTime()}"
        @$('.play-pause').text " #{@formattedTime()}"

    renderPlayButton: ->
      @$('.play-btn-cont').html ck.render @playButtonTemplate, @
      @

    renderEvents: ->
      @$('.events-cont').empty()
      for event in @model.events.models
        @addEventView event
      @

    render: ->
      @$el.html ck.render @template, @
      @$el.css {
        width: '90%'
        left: '30%'
      }
      @setPcEvents()
      @delegateEvents()
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

      @state = new UIState {
        term: ''
        type: null
        student: null
      }

      

      @on 'open', =>
        @setPcEvents()

        @collection.on "load:#{@options.label}", (file)=>
          @model.set 'file', file.attributes
          @model.trigger 'change:file', @model, @model.get('file') 
            #because changing object internals doesn't trigger a change

          @render()
          @setPcEvents()

      @model.on 'change:visible', =>  
        @$('.accordion-group').toggleClass('visible')
        @$('.toggle-visible').toggleClass('icon-eye-open').toggleClass('icon-eye-close').toggleClass('active')

        
      @model.on 'change:muted', (m,muted)=>
        @$('.toggle-mute').toggleClass('icon-volume-up').toggleClass('icon-volume-off').toggleClass('active')
        @pc.volume (if muted then 0.1 else 1)

      @model.on 'change:fullscreen', (m,fs)=>
        @$('.toggle-fullscreen').toggleClass('icon-fullscreen').toggleClass('icon-resize-small').toggleClass('active')

      @state.on 'change', =>
        @renderList()

    
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

      'click .toggle-fullscreen': (e)->
        @model.set 'fullscreen', not @model.get('fullscreen')

      'click .speed-inc': -> @changeSpeed 1
      'click .speed-dec': -> @changeSpeed -1

      'keyup input.search-query': (e)->
        @doSearch $(e.currentTarget).val()

      


        
    doSearch: (term)->
      @state.set 'term', term

    template: ->
      file = if @model.get('file') then new App.File.Model @model.get('file') else null
      div class:"accordion-group#{if @model.get('visible') then ' visible' else ''}", ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle ', ->
            span 'data-toggle':'collapse', 'data-target':".lab-media-#{@label}", class:"media-name icon-#{file?.icon() ? 'play-circle'}", " #{if file? then file.get('title') else 'Media...'}#{if file?.get('type') in ['video','audio'] then ' ('+file.formattedDuration()+')' else ''}" 
            span class:'pull-right', ->
              if file?.get('type') in ['audio','video']
                button class:"btn btn-mini icon-cogs timeline"
                
              if file?
                text "&nbsp;&nbsp;"
                button class:'btn btn-mini change-media icon-remove'

                

        div class:"collapse lab-media-#{@label} accordion-body", ->
          div class:'accordion-inner', ->
            if file?
              div class:'controls-cont', ->
              div class:'scrubber-cont', ->
              div class:'media-cont', ->
            else
              div class:'lab-file-list', ->
                input type:'text', class:'search-query span12', placeholder:'search / filter'
                table class:'table table-condensed table-hover', ->
                  tbody ->

    selectMedia: (e)->
      e.stopPropagation()
      @model.set 'file', null
      @model.set 'visible', false
      @model.set 'currentTime', 0
      @pc?.destroy()
      @pc = null
      @render()


    changeSpeed: (amt)->
      i = _.indexOf @playbackRates, @pc.playbackRate()
      i = if (i+amt is @playbackRates.length) or (i+amt < 0) then i else i + amt
      
      @pc.playbackRate @playbackRates[i]

    formattedTime: ->
      dur = moment.duration(@pc.currentTime()*1000)
      "#{dur.minutes()}:#{(if dur.seconds() < 10 then '0' else '')}#{dur.seconds()}"


    controlsTemplate: ->
      div class:'btn-toolbar span12', ->      
        if (type = @model.get('file').type) is 'image'
          
          div class:"btn-group pull-right", ->
            button rel:'tooltip', title: "Should the student see the #{type}?", class:"btn btn-mini icon-eye-#{ if @model.get('visible') then 'open active' else 'close' } toggle-visible"
            button rel:'tooltip', title: "Fill student's screen with the #{type}?", class:"btn btn-mini icon-#{if @model.get('fullscreen') then 'resize-small active' else 'fullscreen'} toggle-fullscreen"
        
        else if type in ['audio','video']

          div class:'btn-group pull-right', ->
            button class:"btn btn-mini#{ if @pc.playbackRate() is 0.5 then ' disabled' else '' } icon-caret-left speed-dec"
            button class:'btn btn-mini disabled speed', " #{ @rateLabel @pc.playbackRate() } speed"
            button class:"btn btn-mini#{ if @pc.playbackRate() is 2 then ' disabled' else '' } icon-caret-right speed-inc"


          div class:'btn-group', ->
            button rel:'tooltip', title: "Allow student to control #{type} independently?", class:"btn btn-mini icon-hand-up #{ if @model.get('studentControl') then 'active' else ''}"
            if type is 'video'
              button rel:'tooltip', title: "Should the student see the #{type}?", class:"btn btn-mini icon-eye-#{ if @model.get('visible') then 'open active' else 'close' } toggle-visible"
              button rel:'tooltip', title: "Fill student's screen with the #{type}?", class:"btn btn-mini icon-#{if @model.get('fullscreen') then 'resize-small active' else 'fullscreen'} toggle-fullscreen"
            button rel:'tooltip', title: "Should the student hear the #{type} sound?", class:"btn btn-mini icon-volume-#{ if @model.get('muted') then 'off' else 'up active' } toggle-mute"
            


          div class:'btn-group pull-left', ->
            if @pc.paused()
              div class:'btn btn-mini btn-success icon-play play', " #{@formattedTime()}"
            else
              div class:'btn btn-mini btn-inverse icon-pause pause', " #{@formattedTime()}"

          #div class:'btn-group pull-right', ->
            #div class:'btn btn-mini icon-fast-backward back-10', " 10s"
            #div class:'btn btn-mini icon-step-backward back-5', " 5s"

    avTemplate: ->
      file = new App.File.Model @file
      video src:"#{file.src()}", class:"#{file.get('type')}-type"

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
          @scrubber?.destroy()
          @scrubber = new UI.MediaScrubber { min: 0, max: (@pc.duration()*1000), step: 1 }
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
          @scrubber.setVal(0)
          #@renderScrubber()

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
          @$('.play').text " #{@formattedTime()}"
          @$('.pause').text " #{@formattedTime()}"

    renderList: ->
      @$('.lab-file-list tbody').empty()
      for file in @collection.filtered @state.toJSON()
        fv = new Views.LabFile { model: file, label: @options.label }
        fv.render().open @$('.lab-file-list tbody')
      

    render: ->
      file = @model.get('file')
      console.log file
      @$el.html ck.render @template, @options
      if not file?
        @renderList()
      else
        file = new App.File.Model file
        switch file.get('type')
          when 'image'
            imgEl = $('<img/>').attr('src',file.src())
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

      @model.on 'change:control', (student, control)=>
        @render()

      @model.on 'recorder:state', (recorder)=>
        @$('.recorder-state i').removeClass().addClass("icon-#{@recorderStates[recorder.state]}")


    events:
      'click .toggle-control': ->
        @model.toggleControl()
        @model.collection.trigger 'change:control'

    template: ->
      recorderState = @model.get('teacherLabState')?.recorder.state ? 'none'
      td -> i class:"online-status icon-certificate #{if @model.get 'online' then 'online' else ''}#{if @model.get 'help' then ' help' else '' }"
      td "#{@model.get 'name'}"
      td class:'recorder-state', -> i class:"icon-#{ @recorderStates[recorderState] }"
      td ->
        if @model.get('help')
          button class:'btn btn-mini icon-bullhorn'
      td -> 
        button 'data-id':"#{@model.id}", class:"btn btn-mini icon-link box pull-right toggle-control #{if @model.get('control') then 'active' else ''}", 'data-toggle':'button'
      
      

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
      button class:"btn btn-mini icon-eye-#{ if @model?.get('visible') then 'open active' else 'close' } toggle-visible"

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

    initialize: (@options)->

      @state = @options.state = new UI.UIState {
        term: ''
      }

      @collection.on 'help', =>
        @renderHeading()


      @state.on 'change:term', =>
        @renderControls()
        @renderStudentsList()


    events:
      'click .toggle-control-selected': (e)->
        $(e.currentTarget).tooltip('hide')
        @toggleControlSelected()


    doSearch: (term)->
      @state.set 'term', term


    toggleControlSelected: ->
      @collection.toggleControl({ selected: _.pluck @filtered(), 'id' })

    filtered: ->
      @collection.filtered(@state.toJSON())

    someNotControlled: ->
      (_.filter @filtered(), (s)-> not s.get('control')).length

    headingTemplate: ->
      span class:'accordion-toggle icon-group', 'data-toggle':'collapse', 'data-target':'.lab-students', ->
        span class:'', ' Students'
        span class:'pull-right', ->
          if (needHelp = @collection.studentsNeedingHelp())
            span class:'icon-bullhorn need-help', " #{needHelp}"

    controlsTemplate: ->
      someNotControlled = @someNotControlled()
      button rel:'tooltip', title: "#{if someNotControlled then 'Link' else 'Unlink'} all #{@filtered().length} students shown to your lab session", class:"btn btn-mini icon-link box toggle-control-selected pull-right #{if someNotControlled then '' else 'active'}", 'data-toggle':'button'

    template: ->
      div class:'accordion-group', ->
        div class:'accordion-heading ', ->
          # heading template goes here
        div class:'collapse in lab-students accordion-body', ->
          div class:'accordion-inner', ->
            
            table class:'table table-condensed', ->
              thead -> tr -> 
                td  ->
                  input type:'text', class:'search-query span12 student-search', placeholder:'search / filter'
                td class:'controls-cont',->
                  # controls template goes here
            div class:'lab-student-list-cont', ->
              table class:'table table-condensed table-hover lab-student-list', ->
                tbody class:'students'
            
            

    renderHeading: ->
      @$('.accordion-heading').html ck.render @headingTemplate, @
      @

    renderControls: ->
      @$('.controls-cont').html ck.render @controlsTemplate, @
      @$('.controls-cont button').tooltip()
      @delegateEvents()
      @

    renderStudentsList: ->
      ui = @state.toJSON()
      log 'rendering student list'
      @$('.lab-student-list tbody.students').empty()
      studentList = _.sortBy @filtered(), (s)->
        "#{if s.get('control') then '0' else '1'}#{if s.get('online') then '0' else '1'}#{s.get('name')}"

      for stu in studentList
        sv = new Views.LabStudent { model: stu }
        sv.render().open @$('.lab-student-list tbody.students')
      

    render: ->
      @$el.html ck.render @template, @options
      @renderHeading()
      @renderControls()
      @renderStudentsList()
      
      
      @$('input.search-query').typeahead {
        source: @collection.allTags()
      }
      
      @$('input.search-query').on 'keyup', =>
        @doSearch @$('input.search-query').val()

      @$('[rel=tooltip]').tooltip()
      
      @

  class Views.Settings extends Backbone.View

    tagName: 'div'
    className: 'lab-setting-main'

    initialize: (@options)->
      @media = @options.media
      @lab = @options.lab

      @media.on 'change', =>
        @render()

      console.log 'timeline: ',@model.get('timeline')
      @timelineView = new Views.Timeline { model: @lab.get('timeline'), media: @media, lab: @lab }

    events:
      'change input.title': (e)->
        @model.set 'title', $(e.currentTarget).val() 

      'click .tags-list': ->
        tm = new UI.TagsModal { 
          tags: @model.get('tags')
          label: "Tags"
          typeahead: app.tagList()
        }
        tm.render()
        tm.on 'change', (arr,str)=>
          @model.set {
            tags: str
          }
          @render()

      'click .timeline': -> @editTimeLine()

    editTimeLine: ->
      @timelineView.render().open()

    template: ->
      div class:'accordion-group', ->
        div class:'accordion-heading ', ->
          span class:'accordion-toggle icon-wrench', 'data-toggle':'collapse', 'data-target':'.lab-settings', ' Lab Settings'
        div class:'collapse in lab-settings accordion-body', ->
          div class:'accordion-inner', ->
            div class:'control-group', ->
              label "Title"
              input class:'title span10', placeholder:'descriptive name', type:'text', value:"#{@model.get('title')}"
            div class:'control-group act-tags-cont', ->
              label "Tags"
              span class:'tags-list', ->
                if @model.get('tags')
                  span class:'pull-left icon-tags'
                  for tag in @model.get('tags')?.split('|')
                    span class:'tag', " #{tag}"
                  span " +tags"
            div class:'btn-toolbar pull-left', ->
              div class: 'btn-group', ->
                button class:"btn btn-mini icon-cogs timeline #{if @media.get('file') then '' else 'disabled'}", " Timeline"
              div class: 'btn-group', ->
                button class:'btn btn-mini icon-save', " Save..."

    render: ->
      @$el.html ck.render @template, @options
      #@tags.render().open @$('.act-tags-cont')
      @

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container buffer-top'

    initialize: (@options)->
      @bigWb = new App.Board.Views.Main { label: 'Big', model: @model.get('whiteBoardBig') }
      @wbA = new App.Board.Views.Main { label: 'Left', model: @model.get('whiteBoardA') }
      @wbB = new App.Board.Views.Main { label: 'Right', model: @model.get('whiteBoardB') }
      
      @recorder = new Views.Recorder { 
        model: @model.get('recorder')
        collection: @model.get('recordings')
        filez: @model.filez
        students: @model.students
        settings: @model.get('settings') 
      }

      @mediaA = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaA'), label: 'A' }
      #@mediaB = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaB'), label: 'B' }
      #@timeline = new Views.TimeLine

      #@questions = new Views.Questions { model: @model.get('questions') }

      @settings = new Views.Settings { model: @model.get('settings'), media: @model.get('mediaA'), lab: @model }

      @students = new Views.Students { collection: @model.students }

      @recorder.model.on 'change:state', (model, state)=>
        console.log 'recorder change: ',state
        if @recorder.model.get('pauseMediaOnRecord')
          if state in ['recording','waiting-to-record']
            @mediaA.pc?.pause()
            #@mediaB.pc?.pause()
          if state is 'paused-recording'
            @mediaA.pc?.play()
            #@mediaB.pc?.play()

      


    events:
      
      'click [data-toggle=collapse]': (e)->
        $(e.currentTarget).parent('.accordion-group').toggleClass('open')


    template: ->
      #div class:'container-fluid', ->

      # the Files/Students Sidebar
      div class:'row-fluid', ->

        div class:'span3', ->

          
          div class:'lab-settings-cont', ->   
          ###
          div class:'btn-toolbar', ->
            div class:'btn-group', ->
              button class:'btn btn-large icon-wrench'
              button class:'btn btn-large icon-cogs'
              button class:'btn btn-large icon-save'       
          ###
          

          div class:'lab-students-cont', ->
            
        div class:'span9', ->
          
          
          
          div class:'row-fluid', ->
            div class:'span7', ->

              #div class:'lab-timeline-cont', ->


              # Media A
              div class:'lab-media-a-cont', ->

              # Media B
              #div class:'lab-media-b-cont', ->

              # Whiteboard A
              div class:'lab-whiteboard-a-cont', ->

              


            div class:'span5 content', ->

              div class:'lab-recorder-cont', ->

              
              # Whiteboard B
              div class:'lab-whiteboard-b-cont', ->

              #div class:'lab-questions-cont', ->

          div class:'row-fluid', ->
            div class:'lab-whiteboard-big-cont', ->

    render: ->
      @$el.html ck.render @template, @options
      
      @mediaA.render().open @$('.lab-media-a-cont')
      #@mediaB.render().open @$('.lab-media-b-cont')

      @bigWb.render().open @$('.lab-whiteboard-big-cont')
      @wbA.render().open @$('.lab-whiteboard-a-cont')
      @wbB.render().open @$('.lab-whiteboard-b-cont')

      @recorder.render().open @$('.lab-recorder-cont')
      @settings.render().open @$('.lab-settings-cont')

      @students.render().open @$('.lab-students-cont')

      #@questions.render().open @$('.lab-questions-cont')

      #@timeline.render().open @$('.lab-timeline-cont')
      @delegateEvents()
      @

    close: ->
      @$el.hide()
      @

    open: ->
      @$el.show()
      @students.render()
      #@mediaA.render()
      @




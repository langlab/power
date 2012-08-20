module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: (attrs, options)->

      _.extend @, options

      @set {
        'whiteBoardA': new UIState { visible: false }
        'whiteBoardB': new UIState
        'mediaA': new UIState
        'mediaB': new UIState
        'recorder': new UIState { state: 'paused' }
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
        @remoteAction 'recorder', 'update', @get('recorder').toJSON()
        throttledUpdate()

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


  

  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.Recorder extends Backbone.View
    tagName: 'div'
    className: 'recorder'

    initialize: (@options)->

      @model.on 'change', =>
        @render()

    events:
      'click .start-record': ->
        @model.set 'state', 'recording'
      'click .pause-record': ->
        @model.set 'state', 'paused-recording'
      'click .stop-record': ->
        @model.set 'state', 'stopped-recording'
      'click .start-play': ->
        @model.set 'state', 'playing'
      'click .pause-play': ->
        @model.set 'state', 'paused-playing'


    template: ->

      div class:'status', ->
      div class:'recorder-main btn-toolbar', ->
      switch @model.get('state')
        
        when 'paused-recording'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-danger icon-comment start-record', ''
            button class:'btn btn-mini btn-inverse icon-sign-blank stop-record', ''
        
        when 'recording'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-danger icon-pause pause-record', ''
        
        when 'stopped-recording'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-info icon-play start-play', ' '
            button class:'btn btn-mini btn-success icon-download-alt submit-rec', ' '
            button class:'btn btn-mini btn-danger icon-trash trash-rec', ''
        
        when 'playing'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-info icon-pause pause-play'
        
        when 'paused-playing'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-info icon-play start-play'


    render: ->
      @$el.html ck.render @template, @options
      @

  class Views.MediaPlayer extends Backbone.View
    tagName:'div'
    className: 'media-player'

    playbackRates: [0.25,0.5,0.75,1,1.25,1.5,1.75,2]

    rateLabel: (val)->
      switch val
        when 0.25 then '&frac14;x'
        when 0.5 then '&frac12;x'
        when 0.75 then '&frac34;x'
        when 1 then '1x'
        when 1.25 then '1&frac14;x'
        when 1.5 then '1&frac12;x'
        when 1.75 then '1&frac34;x'
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

    events:
      'click .change-media': 'selectMedia'
      'click .speed-option':'changeSpeed'
      'click .play': -> @pc.play()
      'click .pause': -> @pc.pause()
      'click .back-10': -> @pc.currentTime @pc.currentTime()-10
      'click .back-5': -> @pc.currentTime @pc.currentTime()-5
      'click .toggle-mute': -> 
        console.log 'vol',@pc.volume()
        if not @pc.muted() then @pc.mute() else @pc.unmute()
        @renderControls()
      'click .toggle-visible': (e)->
        e.stopPropagation()
        @model.set 'visible', not @model.get('visible')
        @$('.accordion-group').toggleClass('visible')
        @$('.toggle-visible').toggleClass('icon-eye-open').toggleClass('icon-eye-close')

    template: ->
      file = @model.get('file')
      div class:"accordion-group#{if @model.get('visible') then ' visible' else ''}", ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle ', ->
            span 'data-toggle':'collapse', 'data-target':".lab-media-#{@label}", class:"media-name icon-facetime-video", " #{file?.title ? 'Media...'}" 
            span class:'pull-right', ->
              button class:"btn btn-mini icon-eye-#{ if @model.get('visible') then 'open' else 'close' } toggle-visible"
              if file?
                button class:'btn btn-mini change-media icon-remove'
                

        div class:"collapse in lab-media-#{@label} accordion-body", ->
          div class:'accordion-inner', ->
            if file?
              div class:'controls-cont', ->
              div class:'scrubber-cont', ->
              div class:'media-cont', ->
            else
              input type:'text', class:'search-query', placeholder: 'search'
              ul class:'thumbnails lab-file-list', ->

    selectMedia: (e)->
      e.stopPropagation()
      @model.set 'file', null
      @render()


    changeSpeed: (e)->
      e.preventDefault()
      @pc.playbackRate $(e.currentTarget).attr('data-value')
      @$('.speed-label').text " #{$(e.currentTarget).text()} speed"


    controlsTemplate: ->
      div class:'btn-toolbar span12', ->      

        div class:'btn-group pull-left', ->
          a class:"btn btn-mini dropdown-toggle", 'data-toggle':"dropdown", href:"#", ->
            span class:'speed-label', " #{ @rateLabel @pc.playbackRate() } speed"
            span class:"caret"
  
          ul class:"dropdown-menu", ->
            for rate in @playbackRates
              li -> a class:'speed-option', 'data-value':"#{rate}", href:'#', "#{ @rateLabel rate }"

        div class:'btn-group', ->
          button class:"btn btn-mini toggle-mute icon-volume-#{ if @pc.muted() then 'off' else 'up' }",

        div class:'btn-group pull-right', ->
          if @pc.paused()
            div class:'btn btn-mini btn-success icon-play play', " play"
          else
            div class:'btn btn-mini icon-pause pause', " pause"

        div class:'btn-group pull-right', ->
          div class:'btn btn-mini icon-fast-backward back-10', " 10s"
          div class:'btn btn-mini icon-step-backward back-5', " 5s"

    avTemplate: ->
      video ->
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

        @pc.on 'volumechange', =>
          @model.set 'muted', @pc.muted()

        @pc.on 'unmute', =>
          @model.set 'muted', false

        @pc.on 'timeupdate', =>

          @model.set {
            currentTime: @pc.currentTime()
          }, { silent: true }

          @scrubber.setVal(@pc.currentTime() * 1000)

    render: ->
      file = @model.get 'file'
      @$el.html ck.render @template, @options
      if not file?
        for file in @collection.models
          fv = new Views.LabFile { model: file, label: @options.label }
          fv.render().open @$('.lab-file-list') 
      else
        switch file.type
          when 'image'
            imgEl = $('<img/>').attr('src',file.imageUrl)
            imgEl.appendTo @$('.media-cont')
          when 'video','audio'
            @$('.media-cont').html ck.render @avTemplate, @model.attributes
      @

  class Views.LabStudent extends Backbone.View
    tagName: 'tr'
    className: 'lab-student'

    initialize: ->
      @model.on 'change:online', (online)=>
        @$('.icon-heart').toggleClass 'online', online
        @model.collection.trigger 'change:online', @model

    events:
      'click .toggle-control': ->
        @model.toggleControl()

    template: ->
      td -> button 'data-id':"#{@id}", class:"btn btn-mini icon-hand-up box toggle-control #{if @get('control') then 'active' else ''}", 'data-toggle':'button'
      td -> i class:"online-status icon-heart #{if @get 'online' then 'online' else ''}"
      td "#{@get 'name'}"

  class Views.LabFile extends Backbone.View
    tagName: 'li'
    className: 'span3 lab-file'

    initialize: (@options)->

    events:
      'click': -> @model.collection.trigger "load:#{@options.label}", @model

    template: ->
      div class:'thumbnail', ->
        img src:"#{@thumbnail()}"
        div class:'caption',->
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

    events:
      'keyup .editor-area':'update'
      'click button, a':'update'
      'click .accordion-group': -> @model.set 'open', not @model.get('open')
      'click .toggle-visible': (e)->
        e.stopPropagation()
        @model.set 'visible', not @model.get('visible')
        @render()


    update: ->
      @model.set 'html', @editor.simplifiedHTML()
        
    template: ->
      div class:"accordion-group #{if @model.get('visible') then 'visible' else ''}", ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle icon-edit', 'data-toggle':'collapse', 'data-target':".lab-wb-#{ @label }", ->
            text " Whiteboard #{ @label }"
            span class:'btn-group pull-right', ->
              button class:"btn btn-mini icon-eye-#{ if @model.get('visible') then 'open' else 'close' } toggle-visible"
        div class:"collapse#{ if @model.get('open') then ' in' else '' } lab-wb-#{ @label } accordion-body", ->
          div class:'accordion-inner wb-cont', ->
            div class:"wb-cont-#{ @label }", ->


    render: ->
      @$el.html ck.render @template, @options
      @editor.render().open @$(".wb-cont-#{@options.label}")
      @

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->
      
      @wbA = new Views.WhiteBoard { label: 'A', model: @model.get('whiteBoardA') }
      @wbB = new Views.WhiteBoard { label: 'B', model: @model.get('whiteBoardB') }
      
      @recorder = new Views.Recorder { model: @model.get('recorder') }
      
      @mediaA = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaA'), label: 'A' }
      @mediaB = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaB'), label: 'B' }


    events:
      
      'click [data-toggle=collapse]': (e)->
        $(e.currentTarget).parent('.accordion-group').toggleClass('open')



    template: ->
      #div class:'container-fluid', ->

      # top area Timeline
      div class:'row-fluid', ->
        div class:'accordion-group span12', ->
            div class:'accordion-heading', ->
              span class:'accordion-toggle icon-cogs', 'data-toggle':'collapse', 'data-target':'.lab-timeline', ' Timeline'
            div class:'lab-timeline accordion-body collapse', ->
              div class:'accordion-inner', ->
                text "put the timeline in here!"
      
      # the Files/Students Sidebar
      div class:'row-fluid', ->
        
        div class:'span2', ->
          div class:'accordion-group', ->
            div class:'accordion-heading ', ->
              span class:'accordion-toggle icon-group', 'data-toggle':'collapse', 'data-target':'.lab-students', ' Students'
            div class:'collapse in lab-students accordion-body', ->
              div class:'accordion-inner', ->
                div class:'recorder-cont', ->
                table class:'table lab-student-list', ->

        div class:'span5', ->

          # Media A
          div class:'lab-media-a-cont', ->

          # Media B
          div class:'lab-media-b-cont', ->


        div class:'span5 content', ->

          # Whiteboard A
          div class:'lab-whiteboard-a-cont', ->          
          
          # Whiteboard B
          div class:'lab-whiteboard-b-cont', ->


    render: ->
      super()

      for stu in @model.students.models
        sv = new Views.LabStudent { model: stu }
        sv.render().open @$('.lab-student-list')

      @mediaA.render().open @$('.lab-media-a-cont')
      @mediaB.render().open @$('.lab-media-b-cont')

      @wbA.render().open @$('.lab-whiteboard-a-cont')
      @wbB.render().open @$('.lab-whiteboard-b-cont')

      @recorder.render().open @$('.recorder-cont')

      @




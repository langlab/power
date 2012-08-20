module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    defaults:
      message: 'hello!'

    initialize: (attrs, options)->

      _.extend @, options

      @set {
        'whiteBoardA': new UIState
        'whiteBoardB': new UIState
        'mediaA': new UIState
        'mediaB': new UIState
      }


      @attributes.teacherId = @teacher.id
      #@set @teacher.get('labState')

      @recorder = App.Remote.Recorder.Model

      throttledUpdate = _.throttle @updateState, 5000

      @get('whiteBoardA').on 'change', =>
        console.log 'change wba'
        @remoteAction 'whiteBoardA', 'update', @get('whiteBoardA').toJSON()
        throttledUpdate()

      @get('whiteBoardB').on 'change', =>
        @remoteAction 'whiteBoardB', 'update', @get('whiteBoardB').toJSON()
        throttledUpdate()

      ###
      @get('mediaA').on 'change:file', =>
        @remoteAction 'mediaA', 'update', @get('mediaA').toJSON()
        throttledUpdate()

      @get('mediaB').on 'change:file', =>
        @remoteAction 'mediaB', 'update', @get('mediaB').toJSON()
        throttledUpdate()
      ###


    addStudent: (studentId)->
      @sync 'add:student', null, {
        studentIds: [studentId]
        success: (data)=>
          console.log 'student added: ',data
      }

    removeStudent: (studentId)->
      @sync 'remove:student', null, {
        studentIds: [studentId]
        success: (data)=>
          console.log 'student removed', data
      }

    getStudents: ->
      @sync 'read:students', null, {
        success: (data)=>
          console.log 'students: ',data
      }

    getMommaJSON: ->
      mommaJSON =
        whiteBoardA: @get('whiteBoardA').toJSON()

    updateState: =>
      console.log 'updating state...'
      @sync 'update:state', @getMommaJSON(), {
        success: (err,data)=>
          console.log 'state updated: ',data
      }

    remoteAction: (area, action, data)->
      
      actionObj =
        action: action
 
      actionObj[area] = data

      @sync 'action', actionObj, {
        success: (err,data)=>
          console.log 'action complete: ',data
      }

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'


  



  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}



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

    events:
      'click .change-media': 'selectMedia'
      'click .speed-option':'changeSpeed'
      'click .play': -> @pc.play()
      'click .pause': -> @pc.pause()
      'click .back-10': -> @pc.currentTime @pc.currentTime()-10
      'click .back-5': -> @pc.currentTime @pc.currentTime()-5

    template: ->
      div class:'accordion-group', ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle ', ->
            span 'data-toggle':'collapse', 'data-target':".lab-media-#{@label}", class:"media-name icon-facetime-video", " #{@file?.title ? 'Media...'}" 
            span class:'pull-right ', ->
              if @file?
                button class:'btn btn-mini change-media icon-hand-right', ' change media'
        div class:"collapse in lab-media-#{@label} accordion-body", ->
          div class:'accordion-inner', ->
            if @file?
              div class:'scrubber-cont', ->
              div class:'controls-cont', ->
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
        source src:"#{@file.webmUrl}"
        source src:"#{@file.h264Url}"
        source src:"#{@file.mp3Url}"
      

    renderControls: ->
      @$('.controls-cont').html ck.render @controlsTemplate, @
      @

    renderScrubber: ->
      @scrubber.render().open @$('.scrubber-cont')
      @scrubber.on 'change', (v)=>
        @pc.currentTime v/1000

    setPcEvents: ->

      @pc.on 'canplay', =>
        @scrubber = new UI.Slider { max: @pc.duration() * 1000 }
        @renderControls()
        @renderScrubber()

      @pc.on 'playing', => 
        @model.set 'event', 'playing'
        @renderControls()

      @pc.on 'pause', => 
        @model.set 'event', 'pause'
        @renderControls()

      @pc.on 'ended', =>
        @model.set 'event', 'ended'
        @renderScrubber()

      @pc.on 'timeupdate', =>
        @model.set 'event', 'timeupdate'
        @scrubber.setVal(@pc.currentTime() * 1000)


    render: ->
      file = @model.get 'file'
      @$el.html ck.render @template, { file: @model.attributes.file, label: @options.label }
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
            @pc = new Popcorn @$('.media-cont video')[0]
            @setPcEvents()

      @



  class Views.LabStudent extends Backbone.View
    tagName: 'tr'
    className: 'lab-student'

    initialize: ->
      @model.on 'change:online', (online)=>
        @$('.icon-heart').toggleClass 'online', online

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



  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->
      
      @wbA = new UI.HtmlEditor { model: @model.get('whiteBoardA') }
      @wbB = new UI.HtmlEditor { model: @model.get('whiteBoardB') }
      
      @recorder = new App.Remote.Recorder.Views.Control { model: @model.recorder }
      
      @mediaA = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaA'), label: 'A' }
      @mediaB = new Views.MediaPlayer { collection: @model.filez, model: @model.get('mediaB'), label: 'B' }


      @on 'open', =>
        @wbA.open @$('.wb-a-cont')
        @wbB.open @$('.wb-b-cont')
        @$('video').attr('src',@model.filez.at(2).get('webmUrl'))
        @delegateEvents()


      @mediaA.model.on 'change', (m)=>
        console.log 'changing mediaA'
        @model.set 'mediaA', m.attributes
        @model.trigger 'change:mediaA', @model, @model.get('mediaA') 
          #because changing object internals doesn't trigger a change

      @mediaB.model.on 'change', (m)=>
        console.log 'changing mediaB'
        @model.set 'mediaB', m.attributes
        @model.trigger 'change:mediaB', @model, @model.get('mediaB') 
          #because changing object internals doesn't trigger a change

 

      @setRecorderEvents()


    events:
      'keyup .wb-a-cont .editor-area':'updateWhiteBoardA'
      'keyup .wb-b-cont .editor-area':'updateWhiteBoardB'
      'click .wb-a-cont':'updateWhiteBoardA'
      'click .wb-b-cont':'updateWhiteBoardB'

      'click [data-toggle=collapse]': (e)->
        $(e.currentTarget).parent('.accordion-group').toggleClass('open')

      'click .toggle-control': (e)->
        @model.students.get($(e.currentTarget).attr('data-id')).toggleControl()


    setRecorderEvents: ->
      #@model.recorder.on 'record', =>
        #console.log 'record start'


    updateWhiteBoardA: (e)->
      @model.get('whiteBoardA').set 'html', @wbA.simplifiedHTML()

    updateWhiteBoardB: (e)->
      @model.get('whiteBoardB').set 'html', @wbB.simplifiedHTML()


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
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              span class:'accordion-toggle icon-edit', 'data-toggle':'collapse', 'data-target':'.lab-wb-a', ' Whiteboard A'
            div class:'collapse lab-wb-a accordion-body', ->
              div class:'accordion-inner wb-cont', ->
                div class:'wb-a-cont', ->
          
          # Whiteboard B
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              span class:'accordion-toggle icon-edit', 'data-toggle':'collapse', 'data-target':'.lab-wb-b', ' Whiteboard B'
            div class:'collapse lab-wb-b accordion-body', ->
              div class:'accordion-inner wb-cont', ->
                div class:'wb-b-cont', ->

    render: ->
      super()

      for stu in @model.students.models
        sv = new Views.LabStudent { model: stu }
        sv.render().open @$('.lab-student-list')

      @mediaA.render().open @$('.lab-media-a-cont')
      @mediaB.render().open @$('.lab-media-b-cont')

      @wbA.render()
      @wbB.render()

      @recorder.render().open @$('.recorder-cont')

      @




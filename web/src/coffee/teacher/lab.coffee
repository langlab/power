module 'App.Lab', (exports, top)->

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    defaults:
      message: 'hello!'

    initialize: (options)->

      _.extend @, options

      @attributes.teacherId = @teacher.id
      @set @teacher.get('labState')

      @recorder = App.Remote.Recorder.Model

      @on 'change', @updateState, @


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

    updateState: ->
      console.log 'updating state...'
      @sync 'update:state', @toJSON(), {
        success: (err,data)=>
          console.log 'state updated: ',data
      }


  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'


  class UIState extends Backbone.Model



  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}


  class Views.AVPlayer extends Backbone.View
    tagName: 'div'
    className: 'av-player'

    initialize: ->

    template: ->

    render: ->
      super()
      @pc = new Popcorn @el






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
      @model = new UIState @model

      

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
          span class:'accordion-toggle  ', ->
            span class:"#{ 'icon-hand-right'} media-name", "#{@file?.title ? ' Select a media file to show here ...'}", 'data-toggle':'collapse', 'data-target':".lab-media-#{@label}" 
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

    selectMedia: ->
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

      @pc.on 'playing', => @renderControls()
      @pc.on 'pause', => @renderControls()

      @pc.on 'ended', =>
        @renderScrubber()

      @pc.on 'timeupdate', =>
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
      @wbA = new UI.HtmlEditor { html: @model.get 'whiteBoardA' }
      @wbB = new UI.HtmlEditor { html: @model.get 'whiteBoardB' }
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
        @model.trigger 'change', @model, @model.get('mediaA') 
          #because changing object internals doesn't trigger a change

      @mediaB.model.on 'change', (m)=>
        console.log 'changing mediaB'
        @model.set 'mediaB', m.attributes
        @model.trigger 'change', @model, @model.get('mediaB') 
          #because changing object internals doesn't trigger a change

      @setRecorderEvents()


    events:
      'keyup .wb-a-cont .editor-area':'updateWhiteBoardA'
      'keyup .wb-b-cont .editor-area':'updateWhiteBoardB'
      'click .wb-a-cont':'updateWhiteBoardA'
      'click .wb-b-cont':'updateWhiteBoardB'

      'click .toggle-control': (e)->
        @model.students.get($(e.currentTarget).attr('data-id')).toggleControl()


    setRecorderEvents: ->
      #@model.recorder.on 'record', =>
        #console.log 'record start'


    updateWhiteBoardA: (e)->
      @model.set 'whiteBoardA', @wbA.simplifiedHTML()

    updateWhiteBoardB: (e)->
      @model.set 'whiteBoardB', @wbB.simplifiedHTML()


    template: ->
      #div class:'container-fluid', ->

      # top area Timeline
      div class:'row-fluid', ->
        div class:'accordion-group span12', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-timeline', 'Timeline'
            div class:'lab-timeline accordion-body collapse', ->
              div class:'accordion-inner', ->
                text "put the timeline in here!"
      
      # the Files/Students Sidebar
      div class:'row-fluid', ->
        

        div class:'span6', ->

          # Media A
          div class:'lab-media-a-cont', ->

          # Media B
          div class:'lab-media-b-cont', ->
                  


        div class:'span6 content', ->

          div class:'accordion-group', ->
            div class:'accordion-heading ', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-students', 'Students'
            div class:'collapse lab-students accordion-body', ->
              div class:'accordion-inner', ->
                table class:'table lab-student-list', ->

          # Student Recorder
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-recorder', 'Student recorder'
            div class:'collapse in lab-recorder accordion-body', ->
              div class:'accordion-inner recorder-cont', ->

          # Whiteboard A
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-wb-a', 'Whiteboard A'
            div class:'collapse lab-wb-a accordion-body', ->
              div class:'accordion-inner wb-cont', ->
                div class:'wb-a-cont', ->
          
          # Whiteboard B
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-wb-b', 'Whiteboard B'
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




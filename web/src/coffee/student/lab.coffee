module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: ->  

      @set {
        'whiteBoardA': new UIState
        'whiteBoardB': new UIState
        'mediaA': new UIState
        'mediaB': new UIState
        'recorder': new UIState { state: 'clean-slate' }
      }



    remoteAction: (area, action, data)->
      
      actionObj =
        action: action
 
      actionObj[area] = data

      @sync 'action', actionObj, {
        teacherId: top.app.data.student.get('teacherId')
        success: (err,data)=>
          log 'action complete: ',data
      }

    updateState: (model)->
      console.log 'model: ',model
      for area,data of model
        @get(area).set model[area]

      console.log 'triggering join'
      @trigger 'join'

    fromDB: (data)->
      console.log 'lab fromDB: ',data
      {method,model,options} = data

      switch method

        when 'join'
          
          @updateState model
          console.log 'updated'
          
        when 'action'

          {action} = model

          switch model.action
            
            when 'update'
              #log 'update'
              for prop,val of model when prop isnt 'action'
                @get(prop)?.set val




  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'


  class StudentRecording extends Backbone.Model


  class StudentRecordings extends Backbone.Collection
    model: StudentRecording


  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.WhiteBoard extends Backbone.View
    tagName:'div'
    className: 'wb-cont'

    initialize: ->

      @model.on 'change:html', =>
        #console.log 'changing html',@model.get 'html'
        @render()



    render: ->
      @$el.html @model.get('html')
      @

  class Views.MediaPlayer extends Backbone.View
    tagName: 'div'
    className: 'media-cont'

    initialize: ->

      @model.on 'change:file', (m,file)=>
        console.log 'file changed'
        @render()

      @model.on 'change:state', (m,state)=>
        switch state
          when 'playing'
            @pc?.playbackRate m.get('playbackRate')
            @pc?.currentTime m.get('currentTime')
            @pc?.play()
          when 'paused'
            @pc?.currentTime m.get('currentTime')
            @pc?.pause()

      @model.on 'change:currentTime', (m,time)=>
        @pc?.currentTime time

      @model.on 'change:playbackRate', (m,rate)=>
        @pc?.currentTime m.get('currentTime')
        console.log 'changed rate',rate
        @pc?.playbackRate rate

      @model.on 'change:muted', (m,muted)=>
        if muted then @pc?.mute() else @pc?.unmute()

      @model.on 'change:visible', (m,viz)=>
        @$('.media').toggleClass('hid',not viz)


    template: ->
      file = @model.get 'file'
      div class:'media', ->
        if file?
          switch file.type
            when 'image'
              img src:"#{file.imageUrl}"
            when 'video'
              video ->
                source src:"#{file.webmUrl}"
                source src:"#{file.h264Url}"
            when 'audio'
              audio ->
                source src:"#{file.mp3Url}"

    setPcEvents: ->
      type = @model.get('file')?.type
      @pc = Popcorn @$(type)[0]
      @pc.on 'canplay', =>
        @pc.currentTime @model.get('currentTime')
        @pc.playbackRate @model.get('playbackRate')

    render: ->
      @$el.html ck.render @template, @options
      @$('.media').toggleClass('hid',not @model.get('visible'))
      if (type = @model.get('file')?.type) in ['video','audio']
        @setPcEvents()
      @

  class Views.Recorder extends Backbone.View

    tagName:'div'
    className: 'recorder'

    initialize: (@options)->

      @rec = $('applet')[0]

      @model.on 'change:state', (m,state)=>
        @render()

        switch state

          when 'waiting-to-record'
            @sfx 'metronome'

          when 'recording'
            @rec.sendGongRequest 'RecordMedia', 'audio'
            @sfx 'start-record'

          when 'recording-duration'
            @rec.sendGongRequest 'RecordMedia', 'audio'
            @sfx 'start-record'

          when 'paused-recording'
            @sfx 'end-record'
            @rec.sendGongRequest 'PauseMedia', 'audio'

          when 'stopped-recording'
            @rec.sendGongRequest 'StopMedia', 'audio'

          when 'playing'
            @rec.sendGongRequest 'PlayMedia', 'audio'

          when 'paused-playing'
            @rec.sendGongRequest 'PauseMedia', 'audio'

          when 'clean-slate'
            console.log 'clean-slate'
            @rec.sendGongRequest 'StopMedia', 'audio'
            @rec.sendGongRequest 'ClearMedia', 'audio'

          when 'submitting'
            @submitRec()

          when 'submitted'
            @sfx 'submitted'

    submitRec: -> 
      @submitStat = @rec.sendGongRequest 'PostToForm', "http://up.langlab.org/rec?s=#{app.data.student.id}&t=#{app.data.student.get('teacherId')}",'file', "", "#{app.data.student.id}_#{app.data.student.get('teacherId')}.spx"
      if @submitStat then @model.set 'state', 'submitted'

    template: ->
      div class:'alert alert-warning recorder-message', "#{@get('state')}"


  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->

      @wbA = new Views.WhiteBoard { model: @model.get 'whiteBoardA' }
      @wbB = new Views.WhiteBoard { model: @model.get 'whiteBoardB' }

      @mediaA = new Views.MediaPlayer { model: @model.get 'mediaA' }
      @mediaB = new Views.MediaPlayer { model: @model.get 'mediaB' }

      @recorder = new Views.Recorder { model: @model.get('recorder') }

      @wbA.model.on 'change:visible', (m,v)=>
        if v then @wbA.render().open @$('.wb-cont-a')
        else @wbA.remove()

      @wbB.model.on 'change:visible', (m,v)=>
        if v then @wbB.render().open @$('.wb-cont-b')
        else @wbB.remove()




    template: ->



      div class:'row-fluid', ->

        div class:'span6', ->

          div class:'media-cont-a', ->
            

          div class:'media-cont-b', ->


        div class:'span6', ->

          div class:'recorder-cont'

          div class:'wb-cont-a', ->

          div class:'wb-cont-b', ->


    render: ->
      super()

      if @wbA.model.get('visible') then @wbA.render().open @$('.wb-cont-a')
      if @wbB.model.get('visible') then @wbB.render().open @$('.wb-cont-b')

      @mediaA.open @$('.media-cont-a')
      @mediaB.open @$('.media-cont-b')

      @recorder.render().open @$('.recorder-cont')
      
      @delegateEvents()
      @






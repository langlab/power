module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: ->  

      # limit update of full labState to every 5 seconds
      throttledUpdate = _.throttle @updateState, 5000

      @set {
        'whiteBoardA': new UIState
        'whiteBoardB': new UIState
        'mediaA': new UIState
        'mediaB': new UIState
        'recorder': new UIState { state: 'clean-slate' }
        'recordings': new StudentRecordings
      }

      
      @get('recorder').on 'change:state', (model, state)=>
        @remoteAction 'recorder', 'update', model
        throttledUpdate()
      


    remoteAction: (area, action, data)->
      
      actionObj =
        action: action
 
      actionObj[area] = data

      @sync 'action', actionObj, {
        student: top.app.data.student.toJSON()
        success: (err,data)=>
          log 'action complete: ',data
      }


    # save the entire labState to the DB
    updateState: =>
      @sync 'update:state', @getState(), {
        success: (err,data)=>
          log 'state updated: ',data
      }

    setState: (model)->
      console.log 'model: ',model
      for area,data of model
        @get(area)?.set model[area]

      console.log 'triggering join'
      @trigger 'join'

    # retrieve the state as nested JSON data snapshot
    getState: ->
      labState = {}

      for area, state of @attributes
        labState[area] = state.attributes

      labState

    fromDB: (data)->
      console.log 'lab fromDB: ',data
      {method,model,options} = data

      switch method

        when 'join'
          
          @setState model
          console.log 'updated'
          
        when 'action'

          {action} = model

          switch model.action
            
            when 'update'
              #log 'update'
              for prop,val of model when prop isnt 'action'
                @get(prop)?.set val unless (prop is 'recorder' and val.state is 'waiting-for-recordings')




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


  class Views.SubmitError extends Backbone.View
    tagName: 'div'
    className: 'modal fade hide'

    initialize: (@options)->


    events:
      'click .try-again': ->
        @model.set 'state','submitting'
      'click .save-recording':->
        @options.rec.sendGongRequest 'SaveMessage', 'wav/adpcm'
        wait 3000, @$el.modal('hide')

    template: ->
      div class:'modal-header', ->
        h2 class:'icon-exclamation-sign', 'Error submitting recording'
      div class:'modal-body', ->
        p "There was an error sending your recording to the server. You can either try to submit again, or save the file to deliver to your teacher some other way."
      div class:'modal-footer', ->
        button class:'btn icon-share-alt try-again', ' Try to submit again'
        button class:'btn btn-info icon-download save-recording', ' Save to your computer'

    render: ->
      super()
      @$el.modal('show')
      @delegateEvents()

      @$el.on 'hidden', =>
        @remove()
      @


  class Views.Recorder extends Backbone.View

    tagName:'div'
    className: 'recorder'

    initialize: (@options)->

      @rec = $('applet')[0]

      @recTimer = new App.Activity.Timer
      @playTimer = new App.Activity.Timer
      @bigRecTimer = new App.Activity.Timer
      @waitTimer = new App.Activity.Timer
      @setTimerEvents()
      @setStateEvents()

      @submitError = new Views.SubmitError { model: @model, rec: @rec }

      
    setAlertType: (type)->
      for t in ['info','warning','success','danger']
        @$('.recorder-message').removeClass("alert-#{t}")

      @$('.recorder-message').addClass("alert-#{type}")

    setTimerEvents: ->

      @recTimer.on 'tick', (data)=>
        {ticks,secs} = data

        if @model.get('state') is 'recording-duration'
          timeLeft = moment.duration(@model.get('duration') - ticks)
          secsLeft = (Math.floor timeLeft.seconds()) + 1
          minsLeft = Math.floor timeLeft.minutes()
          waitText = "recording, pauses in#{ if minsLeft then ' '+minsLeft+'m' else '' } #{ secsLeft }s"
          @$('.recorder-message').text waitText
        else
          @$('.recorder-message').text "recording now"

      @waitTimer.on 'tick', (data)=>
        {ticks,secs} = data

        timeLeft = moment.duration(@model.get('delay') - ticks)
        secsLeft = (Math.floor timeLeft.seconds()) + 1
        minsLeft = Math.floor timeLeft.minutes()
        
        waitText = "recording in#{ if minsLeft then ' '+minsLeft+'m' else '' } #{ secsLeft }s"
        @$('.recorder-message').text waitText

    setStateEvents: ->

      throttledSubmit = _.throttle @submitRec, 5000

      @model.on 'change:state', (m,state)=>
        @render()

        switch state

          when 'waiting-to-record'
            @waitTimer.start()
            @sfx 'metronome'


          when 'recording'
            @rec.sendGongRequest 'RecordMedia', 'audio'
            @setAlertType 'danger'
            @recTimer.start()
            @bigRecTimer.start()
            @sfx 'start-record'

          when 'recording-duration'
            @rec.sendGongRequest 'RecordMedia', 'audio'
            @setAlertType 'danger'
            @waitTimer.stop()
            @recTimer.start()
            @bigRecTimer.start()
            @sfx 'start-record'

          when 'paused-recording'
            @setAlertType 'warning'
            @collection.add {
              at: @bigRecTimer.currentMSecs() - @recTimer.currentMSecs()
              delay: @model.get('delay')
              duration: @recTimer.currentMSecs()
            }
            @recTimer.stop()
            @bigRecTimer.pause()
            #@renderRecordings()
            @sfx 'end-record'
            @rec.sendGongRequest 'PauseMedia', 'audio'

          when 'stopped-recording'
            @setAlertType 'info'
            @rec.sendGongRequest 'StopMedia', 'audio'
            @recTimer.stop()
            @bigRecTimer.stop()
            #@renderRecordings()

          when 'playing'
            @rec.sendGongRequest 'PlayMedia', 'audio'
            @playTimer.start()

          when 'paused-playing'
            @rec.sendGongRequest 'PauseMedia', 'audio'
            @playTimer.pause()

          when 'stopped-playing'
            @playTimer.stop()

          when 'clean-slate'
            @setAlertType 'info'
            @rec.sendGongRequest 'StopMedia', 'audio'
            @rec.sendGongRequest 'ClearMedia', 'audio'
            @recTimer.stop()
            @playTimer.stop()
            @bigRecTimer.stop()
            @collection.reset()

          when 'submitting'
            @setAlertType 'info'
            @submitRec()
            @rec.sendGongRequest 'StopMedia', 'audio'
            @rec.sendGongRequest 'ClearMedia', 'audio'

          when 'submitted'
            @setAlertType 'success'
            @sfx 'submitted'

          when 'submit-error'
            @submitError.render()
            #$(@rec).addClass 'submit-error'
            #@rec.sendGongRequest 'SaveMessage', 'wav/adpcm'




    submitRec: ->
      console.log 'posting recording!!'
      url = "http://up.langlab.org/rec?s=#{app.data.student.id}&t=#{app.data.student.get('teacherId')}&ts=#{@model.get('lastSubmit')}"
      log url
      @submitStat = @rec.sendGongRequest 'PostToForm', url,'file', "", "#{app.data.student.id}_#{app.data.student.get('teacherId')}_#{@model.get('ts')}.spx"
      if @submitStat then @model.set 'state', 'submitted'
      else @model.set 'state', 'submit-error'

      

    template: ->
      div class:'alert alert-info recorder-message', "#{@get('state')}"


  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->

      @wbA = new Views.WhiteBoard { model: @model.get 'whiteBoardA' }
      @wbB = new Views.WhiteBoard { model: @model.get 'whiteBoardB' }

      @mediaA = new Views.MediaPlayer { model: @model.get 'mediaA' }
      @mediaB = new Views.MediaPlayer { model: @model.get 'mediaB' }

      @recorder = new Views.Recorder { model: @model.get('recorder'), collection: @model.get('recordings') }

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






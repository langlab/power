module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: ->  

      # limit update of full labState to every 5 seconds
      throttledUpdate = _.throttle @updateState, 5000

      @set {
        'whiteBoardBig': new UIState
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
      for area,data of model
        @get(area)?.set model[area]

      @trigger 'join'

    # retrieve the state as nested JSON data snapshot
    getState: ->
      labState = {}

      for area, state of @attributes
        labState[area] = state.attributes

      labState

    fromDB: (data)->
      {method,model,options} = data

      switch method

        when 'join'
          
          @setState model
          
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

  class Views.ModalMsg extends Backbone.View
    tagName:'div'
    className:'modal modal-msg fade hide'



  class Views.ShortInput extends Backbone.View

    initialize: (@options)->
      @config = @options.config
      
      @model.on 'change:answer', (m,s)=>
        @checkAnswer()
      
      @model.on 'change:state', =>
        @updateNotify()


    events:

      'keyup input': (e)->
        if e.which is 9
          e.preventDefault()
          if @model.get('state') is 'correct' then @trigger 'correct'
      
      'mouseout .notify': (e)-> @$('.notify').popover('hide')
      
      'change input': (e)-> 
        @model.set 'answer', $(e.currentTarget).val()
        $(e.currentTarget).focus()

      'dblclick input': (e)->
        console.log JSON.parse Base64 $(e.currentTarget).attr('data-config')

      'click .notify': (e)->
        if @model.get('state') isnt 'correct' then @$('input').focus()
        $(e.currentTarget).popover('show')


    updateNotify: ->

      if @config.get('notifyCorrect')
        @$el.toggleClass('state-correct', @model.get('state') is 'correct')
        @$el.toggleClass('state-feedback', @model.get('state') is 'feedback')
        @$el.toggleClass('state-wrong', @model.get('state') is 'wrong')

      switch @model.get('state')

        when 'correct'
          if @config.get('notifyCorrect')
            @$('.notify').removeClass().addClass('notify add-on icon-ok')
            @$('.notify').popover('destroy')
            @$('.notify').popover {
              title: @config.get('label')
              content: @model.get('feedbacks')[0]
              placement: 'top'
            }
            @sfx 'bbell'
            @trigger 'correct'

        when 'feedback'
 
          fbContent = ""
          
          for fbk in @model.get('feedbacks')
            fbContent = "#{fbContent}<li>#{fbk}</li>"

          @$('.notify').removeClass().addClass('notify add-on icon-star')
          @$('.notify').popover('destroy')
          @$('.notify').popover {
            title: @config.get('label')
            content: fbContent
            placement: 'top'
          }
          #@$('.notify').popover 'show'

        else
          @$('.notify').removeClass().addClass('notify add-on icon-question-sign')
          @$('.notify').popover('destroy')
          @$('.notify').popover {
            title: @config.get('label')
            content: 'Type your answer in the box, then click here again to check your answer.'
            placement: 'top'
          }

    match: (re,str,cb)->
      {useRegex,caseSensitive} = @config.toJSON()
      @io.emit 'tre', 'compare', {
        re: re
        str: str
        literal: not useRegex
        caseSensitive: caseSensitive
      }, (err,resp) -> cb err, resp[0]


    checkAnswer: ->
      {answer,feedbacks,useRegex,caseSensitive,notifyAlmost} = @config.toJSON()
      
      att = @model.get('attempts') ? {}
      att[moment().valueOf()] = @model.get('answer')
      
      @model.set 'attempts', att
      val = @model.get('answer').trim()
      
      @model.set 'state', 'typing'

      @fbArr = []
      @match answer, val, (err,resp)=>
        if (resp.edits is '0')
          @model.set {
            state: 'correct'
            feedbacks: ["#{@model.get('correctFeedback') ? 'Good job!'}"]
          }
        
        else 
          if notifyAlmost
            if (resp.edits <= 2)
              @fbArr.push "You are so close! Just make #{resp.edits} little change#{if resp.edits > 1 then 's' else ''} and you'll have it right!"
              @model.set { state: 'feedback', feedbacks: @fbArr }

          addFbIfMatch = (fbkObj)=> 
            {expr, fb} = fbkObj
            @match expr, val, (err,resp)=>
              if resp.edits < 1
                console.log 'pushing: ',fb
                if fb
                  @fbArr.unshift fb
                  @model.set { state: 'feedback', feedbacks: @fbArr }
                  @model.trigger 'change:state'

          for fbkObj in feedbacks
            addFbIfMatch(fbkObj)
                
          

        

    render: ->
      @$el.toggleClass('input-append')
      @$('.notify').toggleClass('add-on icon-question-sign')
      @$('.notify').popover {
        title: @config.get('label')
        content: 'Type your answer in the box.'
        placement: 'top'
      }
      if (kb = @config.get('kb'))
        @kb = new UI.IKeyboard { language: kb }
        @kb.render().open @$el
        @kb.on 'select', => @checkAnswer()
      @



  class Views.WhiteBoard extends Backbone.View
    tagName:'div'
    className: 'wb-cont'

    initialize: ->
      @inputs = {}

      @model.on 'change:html', =>
        @render()

      @model.on 'change:state', (m,state)=>
        if state is 'submit' then @submitAnswers()

    events: ->
      'click .wb-tts': (e)->
        sp = new Spinner({length:3, radius:1, lines: 8, corners: 0, trail: 50, width: 2, color: 'blue'}).spin($(e.currentTarget).find('.spinner')[0])
        pc = @tts JSON.parse Base64.decode $(e.currentTarget).attr('data-config')
        pc.on "canplay", => 
          $(sp.el).remove()

      'dblclick .wb-input input': (e)->
        console.log JSON.parse Base64.decode $(e.currentTarget).parent().attr('data-config')

    addInput:(wbInput) ->
      data = JSON.parse Base64.decode $(wbInput).attr('data-config')
      console.log 'config data',data
      
      v = new Views.ShortInput {
          el: wbInput
          model: new Backbone.Model
          config: new Backbone.Model data
      }
      
      console.log 'v:',v
      v.render()

      v.on 'correct', =>
        myId = v.$el.attr('id')
        ids = _.map @$('.wb-input'), (el)-> $(el).attr('id')
        nextIndex = ids.indexOf(myId)+1
        if nextIndex >= ids.length then nextIndex = 0
        @$("##{ids[nextIndex]} input").focus()

      @inputs[v.config.get('id')] = v
      console.log 'inputs:',@inputs

    renderInputs: ->
      for wbInput in @$('.wb-input')
        @addInput wbInput

    submitAnswers: ->
      console.log @inputs
  
      answers = _.map(@inputs, (i)-> { type:'short', question: i.config.toJSON(), answer: i.model.toJSON() })
      
      context = { type: 'whiteboard', state: @model.toJSON() }
      
      console.log 'answers:',answers
      response = new App.Response.Model {
        owner: app.data.student.get('teacherId')
        answers: answers
        context: context
      }

      console.log 'resp',response
      
      response.save {}, {
        
        success: (data)=>
          @model.set 'state', 'waiting'
          @trigger 'inputs:submitted'
          @inputs = []
          @render()
          console.log 'success: ',data

        error: (data)=>
          console.log 'error', data
      }
      
      
        
    render: (msg)->
      @$el.html @model.get('html')
      @renderInputs()
      @delegateEvents()
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
        @pc?.playbackRate rate

      @model.on 'change:muted', (m,muted)=>
        if muted then @pc?.mute() else @pc?.unmute()
        @pc?.currentTime m.get('currentTime')

      @model.on 'change:visible', (m,viz)=>
        @$('.media').toggleClass('hid',not viz)
        @pc?.currentTime m.get('currentTime')

      @model.on 'change:fullscreen', (m,fs)=>
        @pc?.currentTime m.get('currentTime')
        @$el.toggleClass 'fullscreen',fs
        #wait 200, => @pc?.currentTime m.get('currentTime')


    template: ->
      file = new App.File.Model @model.get('file')
      div class:"media", ->
        if file?
          switch file.get('type')
            when 'image'
              img src:"#{file.src()}"
            when 'video'
              video src:"#{ file.src() }"
            when 'audio'
              audio ->
                source src:"#{file.src()}"

    setPcEvents: ->
      type = @model.get('file')?.type
      @pc = Popcorn @$(type)[0]
      @pc.on 'canplay', =>
        @pc.currentTime @model.get('currentTime')
        @pc.playbackRate @model.get('playbackRate')
        log 'state: ',@model.get 'state'
        if @model.get('state') is 'playing'
          @pc.play()

    render: ->
      @$el.html ck.render @template, @options
      @$('.media').toggleClass('hid',not @model.get('visible'))
      @$el.toggleClass('fullscreen',@model.get('fullscreen'))
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

    timeDisplay: (dur)->
      dur = moment.duration dur
      "#{dur.minutes()}:#{(if dur.seconds() < 10 then '0' else '')}#{dur.seconds()}"

    setTimerEvents: ->

      @recTimer.on 'tick', (data)=>
        {ticks,secs} = data

        if @model.get('state') is 'recording-duration'
          timeLeft = moment.duration(@model.get('duration') - ticks)
          secsLeft = (Math.floor timeLeft.seconds()) + 1
          minsLeft = Math.floor timeLeft.minutes()
          waitText = "RECORDING NOW, pauses in#{ if minsLeft then ' '+minsLeft+'m' else '' } #{ secsLeft }s"
          @$('.recorder-message').text waitText
        else
          @$('.recorder-message').text "RECORDING NOW, #{@timeDisplay(ticks)} so far"

        # show audio level as a box shadow
        audioLevel = 100 * @rec.sendGongRequest 'GetAudioLevel', ''
        @$('.recorder-message').css('box-shadow',"0px 0px #{audioLevel}px")

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
            @rec.sendGongRequest 'RecordMedia', 'audio', 1200000
            @setAlertType 'danger'
            @recTimer.start()
            @bigRecTimer.start()
            @sfx 'start-record'

          when 'recording-duration'
            @rec.sendGongRequest 'RecordMedia', 'audio', 1200000
            @setAlertType 'danger'
            @waitTimer.stop()
            @recTimer.start()
            @bigRecTimer.start()
            @sfx 'start-record'

          when 'paused-recording'
            @setAlertType 'warning'
            @collection.add {
              question: @model.get('question')
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
      #console.log 'posting recording!!'
      
      dataObj =
        s: app.data.student.id
        t: app.data.student.get('teacherId')
        ts: @model.get('lastSubmit')
        title: @model.get('title')
        tags: @model.get('tags')
        recordings: @collection.toJSON()

      #console.log 'submitting ',dataObj

      data = Base64.encode JSON.stringify dataObj

      url = "http://up.langlab.org/rec?data=#{data}"
      log dataObj, url
      @submitStat = @rec.sendGongRequest 'PostToForm', url,'file', "", "#{app.data.student.id}_#{app.data.student.get('teacherId')}_#{@model.get('ts')}.spx"
      if @submitStat then @model.set 'state', 'submitted'
      else @model.set 'state', 'submit-error'

      

    template: ->
      div class:'alert alert-info recorder-message', "#{@get('state')}"


  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'student-lab-view container buffer-top'

    initialize: ->

      @wbBig = new Views.WhiteBoard { model: @model.get('whiteBoardBig'), cont: '.wb-cont-big' }
      @wbA = new Views.WhiteBoard { model: @model.get('whiteBoardA'), cont: '.wb-cont-a' }
      @wbB = new Views.WhiteBoard { model: @model.get('whiteBoardB'), cont: '.wb-cont-b' }

      @mediaA = new Views.MediaPlayer { model: @model.get 'mediaA' }
      @mediaB = new Views.MediaPlayer { model: @model.get 'mediaB' }

      @recorder = new Views.Recorder { model: @model.get('recorder'), collection: @model.get('recordings') }

      for wb in [@wbBig, @wbA, @wbB]
        @setWbEvents(wb)
        

      
    setWbEvents: (wb)->
      wb.model.on 'change:visible', (m,vis)=>
        if vis then wb.render().open @$("#{wb.options.cont}")
        else wb.remove()

      wb.on 'inputs:submitted', =>
        @$('.msg').text('answers submitted!')



    template: ->
      
      

      div class:'row-fluid', ->

        div class:'span7', ->


          div class:'media-cont-a', ->

          div class:'media-cont-b', ->

          div class:'wb-cont-a', ->


        div class:'span5', ->

          div class:'msg'
          div class:'recorder-cont'

          div class:'wb-cont-b', ->

      div class:'row-fluid', ->

        div class:'wb-cont-big', ->

    render: ->
      

      @$el.html ck.render @template, @options

      if @wbBig.model.get('visible') then @wbBig.render().open @$('.wb-cont-big')
      if @wbA.model.get('visible') then @wbA.render().open @$('.wb-cont-a')
      if @wbB.model.get('visible') then @wbB.render().open @$('.wb-cont-b')

      @mediaA.render().open @$('.media-cont-a')
      @mediaB.render().open @$('.media-cont-b')

      @recorder.render().open @$('.recorder-cont')

      @delegateEvents()

      @







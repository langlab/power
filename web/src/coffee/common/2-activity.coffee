
module 'App.Activity', (exports, top)->

  class Timer

    cueTimes: []

    constructor: (@options = {})->

      _(@).extend Backbone.Events

      _.defaults @options, {
        tickBank: 0 
        cues: []
        autostart: false
        loop: false
        duration: null
        speed: 1
      }

      @tickBank = @options.tickBank
      @cues = @options.cues
      @setStatus 'initialized'

      if @options.autostart then @start()


    normalize: (secs)->
      Math.floor(secs*10)

    seek: (secs)->
      @tickBank = Math.floor(secs*1000)
      @multiTrigger 'event', 'seek', { from: @currentSecs(), to: secs }
      @

    start: (silent=false)->

      @setStatus 'started', silent

      @tickMark = Date.now()

      @engine = doEvery 25, =>

        @tickBank -= (@tickMark - (@tickMark = Date.now())) * @options.speed

        @multiTrigger 'event', 'tick'

        if (thisTick = @normalize(@tickBank/1000)) in @cueTimes

          @multiTrigger 'event', 'cue', { comment: @comment }

          for act in @cues when Math.floor(act.at*10) is thisTick
            act.fn()

        if @options.duration and thisTick is @normalize(@options.duration)
          @multiTrigger 'event', 'ended'
          if @options.loop then @restart() else @stop()

      @

    pause: (silent=false)->
      clearTimeout @engine
      @setStatus 'paused', silent
      @

    togglePlay: (silent=false)->
      if @status is 'started' then @pause() else @start()
      @

    stop: (silent=false)->
      @pause(true)
      @tickBank = 0
      @setStatus 'stopped', silent
      
      
      @

    restart: (silent=false)->
      @multiTrigger 'event', 'restarted'
      @pause(true).stop(true).start()
      @


    currentSecs: ->
      @normalize(@tickBank/1000)/10

    currentMSecs: ->
      @tickBank

    currentTimeObj: ->
      totalSecs = @currentSecs()
      hrs = Math.floor(totalSecs/3600)
      mins = Math.floor((totalSecs-(3600*hrs))/60)
      secs = Math.floor(totalSecs - (hrs*3600) - (mins*60))
      tenths = Math.floor(10*(totalSecs - secs))

      timeObj =
        hrs: hrs
        mins: mins
        secs: secs
        tenths: tenths

    setSpeed: (speed)->
      @options.speed = speed


    addCues: (newCues)->

      if not _.isArray newCues then newCues = [newCues]

      for cue in newCues
        
        cue.fn = _.debounce(cue.fn, 500, true)
        @cues.push cue
        @cueTimes.push @normalize(cue.at)

      @

    setStatus: (@status, silent=false)->
      if not silent
        @multiTrigger 'status', @status

    multiTrigger: (type, name, data = {})->
      _.extend data, { secs: @currentSecs(), ticks: @tickBank, type: type, name: name }
      @trigger name, _.extend data, { secs: @currentSecs(), ticks: @tickBank, type: type }
      @trigger type, _.extend data, { secs: @currentSecs(), ticks: @tickBank, name: name }
      @trigger 'any', _.extend data, { secs: @currentSecs(), ticks: @tickBank, type: type, name: name } 

  class Time
    constructor: (@totalSecs)->
      @intSecs = Math.floor @totalSecs
    
    getSecs: ->
      @secs ? @secs = @intSecs % 60

    getMins: ->
      @mins ? @mins = Math.floor ((@intSecs % 3600) / 60)

    getHrs: ->
      @hrs or @hrs = Math.floor(@intSecs/3600)      

    getTenths: ->
      @tenths ? @tenths = Math.floor (10*(@totalSecs - @intSecs))

    getSecStr: ->
      (if (s = @getSecs()) < 10 then "0" else "")+s

    getMinStr: ->
      (if (m = @getMins()) < 10 then "0" else "")+m

    getHrStr: ->
      (if (h = @getHrs()) < 10 then "0" else "")+h

    setSecs: (@totalSecs)->
      @intSecs = Math.floor @totalSecs
      @hrs = @mins = @secs = @tenths = null
      @

    getTimeStr: ->
      "#{ (if @getHrs() then @getHrStr()+":" else "") }#{ @getMinStr() }:#{ @getSecStr() }.#{ @getTenths() }"

  exports.Time = Time
  
  class Model extends Backbone.Model
    initialize: ->
      @events = new App.Activity.Event.Collection @get('events')
      @events.duration = @get('duration')
      @timer = new Timer {
        duration: @get('duration')
      }


  exports.Views = Views = {}

  
  class Views.Timeline extends Backbone.View
    tagName: 'div'
    className: 'timeline'

    initialize: ->
      @pixelScaleFactor = $(window).width()*0.94 / @model.get('duration')

      @on 'open', =>
        
        @zoomControl.on 'change', (newZoomLevel)=>
          console.log newZoomLevel
          @scaleTime(newZoomLevel)
          @moveCursorToTime 'timer', @timer.model.currentSecs()

        @scaleTime(1)

      $(window).resize =>
        @pixelScaleFactor = $(window).width()*0.94 / @model.get('duration')
        @render()

      
      @timer = new Views.Timer { model: @model.timer }
      @zoomControl = new UI.Slider { min: 1, max: 4 }

      @model.timer.on 'event', (data)=>
        if data.name in ['seek','tick']
          @moveCursorToTime 'timer', s = @model.timer.currentSecs()
          t = new Time s
          @$(".cursor-mark.active .time-info").text t.getTimeStr()

      @model.timer.on 'status', (data)=>
        if data.name is 'started' then @$('.timer-mark').addClass('active')
        else if data.name is 'stopped'
          @$('.timer-mark').removeClass('active')
          @moveCursorToTime 'timer', @model.timer.currentSecs()


    events:
      'mousedown .tick-marks': (e)->
        target = $(e.target)
        extra = $(e.target).position().left
        x = (if target.hasClass('lbl') then 0 else e.offsetX) + extra
        if @userDragging then @model.timer.seek @toSecs(x)
        @userDragging = true
        @model.timer.seek Math.round(@toSecs(x))
        

      'mouseup .tick-marks': (e)->
        @userDragging = false
        @$('.user-mark').show()


      'mousemove .tick-marks': (e)->
        target = $(e.target)
        extra = $(e.target).position().left
        x = (if target.hasClass('lbl') then 0 else e.offsetX) + extra
        if @userDragging then @model.timer.seek @toSecs(x)
        @moveCursorToTime 'user', Math.round(@toSecs(x))

      'mouseover .tick-marks': (e)->
        @$('.user-mark').show()

      'mouseout .tick-marks': (e)->
        @$('.user-mark').hide()


    moveCursorTo: (type='',x)->
      @$(".cursor-mark#{ if type then '.'+type+'-mark' else '' }").css 'left', x
      t = new Time @toSecs(x)
      @$(".user-mark .time-info").text t.getTimeStr()
      @

    moveCursorToTime: (type='',secs)->
      pixels = @toPixels(secs)
      @moveCursorTo type, pixels
      @

    toPixels: (secs)->
      secs*$('.time-cont').width()/@model.get('duration')

    toSecs: (pixels)->
      pixels * @model.get('duration') / @$('.time-cont').width()




    scaleTime: (@zoomLevel)->
      console.log 'scaleTime ',@zoomLevel, @pixelScaleFactor
      val = @zoomLevel * @pixelScaleFactor
      @$('.time-cont').width (val * @model.get('duration'))
      for m,i in @$('.mark,.lbl')
        s = $(m).data('sec')
        $(m).css 'left', "#{Math.floor(val*s)}px"
        

      @moveCursorToTime @timer.model.currentSecs()

      @addEvents()
      


    template: ->
      div class:'time-window', ->
        div class:'time-cont', ->
          div class:'time', ->
          
          div class:'cursor-mark user-mark', ->
            div class:'time-info', 'xx:xx:xx'

          div class:'cursor-mark timer-mark', ->
            div class:'time-info', 'xx:xx:xx'


          div class:'tick-marks', ->
            for sec in [0..Math.floor(@model.get('duration'))]
              type = if (sec % 60 is 0) then 'minute' 
              else if (sec % 30 is 0) then 'half-minute' 
              else if (sec % 15 is 0) then 'quarter-minute' 
              else if (sec % 5 is 0) then 'five-second' else 'second'
              
              div class:"#{type}-mark mark",'data-sec':"#{sec}"
              markLbl = if type in ['half-minute','quarter-minute'] then (sec % 60)+'s' else (sec / 60)+'m'
              if type in ['half-minute','quarter-minute','minute']
                span class:"#{type}-mark-lbl lbl", 'data-sec':"#{sec}","#{markLbl}"

      div class:'timer-cont', ->
      div class:'time-scroll-cont'
      div class:'scale-slider'



    addEvent: (ev)->
      ev.view?.remove()
      ev.view = new App.Activity.Event.Views.Event {model: ev}
      ev.view.renderIn @$('.time')


    render: ->
      
      @$el.html ck.render @template, @
      @timer.render().open @$('.timer-cont')
      @zoomControl.render().open @$('.scale-slider')
      @

    addEvents: ->
      @addEvent(ev) for ev in @model.events.models
      @

  
  class Views.Timer extends Backbone.View
    tagName: 'div'
    className: 'timer'

    initialize: ->
      @model.on 'tick', => @renderClock()

      @model.on 'seek', => @renderClock()

      @model.on 'status', (event)=>
        switch event.name
          when "started"
            @$('.toggle-play').removeClass('btn-success')
            @$('.toggle-play i').removeClass('icon-play').addClass('icon-pause')
            @$('.stop').removeClass('disabled')
          when "paused","stopped"
            @$('.toggle-play').addClass('btn-success')
            @$('.toggle-play i').removeClass('icon-pause').addClass('icon-play')
          when "stopped"
            @$('.stop').addClass('disabled')
            @renderClock()



    events:
      'click .toggle-play': -> @model.togglePlay()
      'click .stop': -> @model.stop()
      'click .speed-control a': (e)->
        @$('.speed-label').text $(e.currentTarget).text()+' '
        @model.setSpeed $(e.currentTarget).data('value')

    clockTemplate: ->
      time = @currentTimeObj()
      span class:'mins digit', "#{ time.mins }"
      text " : "
      span class:'secs digit', "#{ time.secs }"
      text " . "
      span class:'tenths digit', "#{ time.tenths }"

    template:->
      div class:'clock span4', ->
        
      div class:'btn-group span4', ->
        button class:'btn btn-success toggle-play', ->
          i class:'icon-play'
        button class:'btn btn-inverse stop', ->
          i class:'icon-stop'
        a class:'btn dropdown-toggle btn-inverse','data-toggle':'dropdown',href:'#', ->
          span class:'speed-label', '1x '
          span class:'caret'
        ul class:'dropdown-menu speed-control', ->
          li -> a 'data-value':'0.25','&frac14;x'
          li -> a 'data-value':'0.5','&frac12;x'
          li -> a 'data-value':'0.75','&frac34;x'
          li -> a 'data-value':'1','1x'
          li -> a 'data-value':'1.5','1&frac12;x'
          li -> a 'data-value':'2','2x'

    renderClock: ->
      @$('.clock').html ck.render @clockTemplate, @model

    render: ->
      @$el.html ck.render @template, @model
      @renderClock()
      @



  [exports.Timer, exports.Model] = [Timer, Model]
  

module 'App.Activity.Event', (exports, top)->

  class Model extends Backbone.Model


  class Collection extends Backbone.Collection
    model: Model

    initialize: ->
      @duration ?= 60

  exports.Views = Views = {}

  class Views.Event extends Backbone.View
    tagName: 'div'
    className: 'event'

    renderIn: (parent)->
      console.log parent.width()
      style =
        width: @model.get('duration') * $(parent).width() / @model.collection.duration
        left: @model.get('start') * $(parent).width() / @model.collection.duration
      @$el.css style
      @$el.appendTo parent
      @

  [exports.Model, exports.Collection] = [Model, Collection]

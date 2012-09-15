
module 'App.Utils', (exports, top)->
  
  class Time

    @formatAsClockTime: (duration,inSecs=false)->
      if inSecs then duration = duration*1000
      mdur = moment.duration(duration)
      mins = mdur.minutes()
      secs = if (s = mdur.seconds()) < 10 then "0#{s}" else "#{s}"
      "#{mins}:#{secs}"

    @formatAsMinsSecs: (duration,inSecs=false)->
      if inSecs then duration = duration*1000
      mdur = moment.duration(duration)
      mins = if (m = mdur.minutes()) then "#{m}m" else ""
      secs = if (s = mdur.seconds()) then "#{s}s" else ""
      "#{mins}#{if (mins and secs) then ' ' else ''}#{secs}"


  class Timer
    
    constructor: (@opts={})->
      _(@).extend Backbone.Events
      _.defaults @opts, {
        start: 0
      }

      @tickBank = 0
      @cues = []

    start: ->
      @tickMark = Date.now()
      @ticker = doEvery 25, =>
        @newTickmark = Date.now()
        @tickBank += @newTickmark - @tickMark
        @tickMark = @newTickmark
        @trigger 'tick', @tickBank
        @checkCues()
      @

    stop: ->
      clearInterval @ticker
      @newTickMark = Date.now()
      @tickBank += @newTickMark - @tickMark
      @tickMark = @newTickmark
      @

    reset: ->
      @stop()
      @tickBank = 0
      @

    restart: ->
      @reset()
      @start()
      @

    _normalize: (val)->
      Math.floor val/100

    checkCues: ->
      now = @tickBank
      for cue in @cues
        if @_normalize(cue.at) is @_normalize(now)
          cue.fn()

    seek: (@tickBank)->
      @

    addCue: (cue)->
      @cues.push {
        at: cue.at
        fn: _.debounce cue.fn, 1000, true
      }
      @

    addCues: (cues)->
      @addCue cue for cue in cues
      @

    at: (tick,fn)->
      @cues.push {
        at: tick
        fn: _.debounce fn, 1000, true
      }
      @

    clearCues: ->
      @cues = []
      @

    msecs: -> @tickBank

    secs: -> Math.floor(@tickBank/100)/10

  _.extend exports, {
    Time: Time
    Timer: Timer
  }

  class Recorder

    constructor: (@el)->
      



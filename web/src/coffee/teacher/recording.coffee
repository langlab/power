
module 'App.Recording', (exports,top)->
  
  class Model extends App.File.Model

  class Collection extends Backbone.Collection
    model: Model


  exports.Views = Views = {}

  class Views.Recorder extends Backbone.View
    tagName: 'div'
    className: 'recorder'

    initialize: ->

    events:
      'click .record':'record'
      'click .play':'play'
      'click .stop':'stop'
      'click .pause':'pause'

    template: ->
      applet class:'recorder-applet', archive:'/java/nanogong.jar', code:'gong.NanoGong', width:150, height:40, ->
        param name:'AudioFormat', value:'Speex'
        param name:'MaxDuration', value:'1200'
        param name:'SamplingRate', value:'16000'

      div class:'scrubber', ->

      div class:'status'

      div class:'recorder-main', ->
        button class:'btn btn-danger record state-stopped state-closed state-paused-recording', ->
          i class:'icon-comment'
          text ' rec'
        button class:'btn pause state-playing state-recording', ->
          i class:'icon-pause'
          text ' pause'
        button class:'btn btn-success play state-paused state-stopped state-paused', ->
          i class:'icon-play'
          text ' play'
        button class:'btn btn-inverse stop state-paused state-recording state-playing state-paused-recording', ->
          i class:'icon-stop'
          text ' stop'



    appEvents: ->
      doEvery 200, => @statusCheck()
        

    handleNewStatus: ->
      @$('.recorder-main .btn').hide()
      @$(".recorder-main .state-#{ @status }").show()

    statusCheck: ->
      if @status isnt @status = @getStatus().replace(' ','-')
        @trigger 'status', @status
        @$('.status').text @status
        @handleNewStatus()


    render: ->
      super()
      @rec = @$('.recorder-applet')[0]
      @appEvents()
      @scrubber ?= new UI.Slider()
      @scrubber.render().open @$('.scrubber')
      @


    _req: (args...)-> 
      res =@rec.sendGongRequest(args...)
      #@statusCheck()
      res

    record: -> duration = @_req 'RecordMedia', 'audio', 1200000; @
    stop: -> @_req 'StopMedia', 'audio'; @
    pause: -> @_req 'PauseMedia', 'audio'; @
    clear: -> @_req 'ClearMedia', 'audio'; @
    play: -> @_req 'PlayMedia', 'audio'; @
    getStatus: -> @_req 'GetMediaStatus', 'audio'
    getTime: -> @_req 'GetMediaTime', 'audio'
    setTime: (s)-> @_req 'SetMediaTime', 'audio', Math.floor(s*1000); @
    getAudioLevel: -> @_req 'GetAudioLevel', 'audio'
    upload: -> @_req 'PostToForm', 'http://lingualab.io/upload', 'file', '', 'recording.spx'


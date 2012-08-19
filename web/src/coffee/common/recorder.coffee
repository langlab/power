module 'App.Recorder', (exports, top)->

  exports.Views = Views = {}

  class Views.Student extends Backbone.View
      tagName: 'div'
      className: 'recorder'

      initialize: ->

      events:
        'click .record':'record'
        'click .play':'play'
        'click .stop':'stop'
        'click .pause':'pause'

      template: ->
        
        div class:'scrubber', ->

        div class:'status'

        div class:'recorder-main btn-toolbar', ->
          div class:'btn-group', ->
            button class:'btn btn-mini play state-paused state-stopped state-paused', ->
              i class:'icon-play'
              text ' play'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-danger record state-stopped state-closed state-paused-recording', ->
              i class:'icon-comment'
              text ' record now'
            button class:'btn btn-mini btn-danger state-stopped state-closed state-paused-recording', ->
              span 'in 5s'
            button class:'btn btn-mini btn-danger state-stopped state-closed state-paused-recording', ->
              span '10s'
            button class:'btn btn-mini btn-danger state-stopped state-closed state-paused-recording', ->
              span '15s'
          div class:'btn-group', ->
            button class:'btn btn-mini pause state-playing state-recording', ->
              i class:'icon-pause'
              text ' pause'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-success stop state-paused state-recording state-paused-recording', ->
              i class:'icon-ok'
              text ' finished'
          div class:'btn-group', ->
            button class:'btn btn-mini btn-success stop state-paused state-recording state-paused-recording', ->
              i class:'icon-ok'
              text ' save all responses'



      appEvents: ->
        doEvery 200, => @statusCheck()
          

      handleNewStatus: ->
        @$('.recorder-main .btn').hide()
        @$('.status').hide()
        @$(".recorder-main .state-#{ @status }").show()

      statusCheck: ->
        if @status isnt @status = @getStatus().replace(' ','-')
          @trigger 'status', @status
          @$('.status').text @status
          @handleNewStatus()


      render: ->
        super()
        @rec = $('.recorder-applet')[0]
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
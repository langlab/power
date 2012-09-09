module 'App.File', (exports,top)->

  class Model extends Backbone.Model

    baseUrl: 'https://lingualabio-media.s3.amazonaws.com'
    syncName: 'file'
    idAttribute: '_id'
    thumbBase: "https://s3.amazonaws.com/lingualabio-media"

    iconHash: {
      image: 'picture'
      video: 'play-circle'
      audio: 'volume-up'
      pdf: 'file'
    }

    studentName: ->
      if @get("student")
        top.app.data.students.get(@get('student'))?.get('name')
      else null

    src: ->
      base = @baseUrl
      switch @get 'type'
        when 'image'
          "#{base}/#{@get('filename')}.#{@get('ext')}"
        when 'video'
          if top.Modernizr.video.webm then "#{base}/#{@get('filename')}.webm"
          else if top.Modernizr.video.h264 then "#{base}/#{@get('filename')}.mp4"
        when 'audio'
          "#{base}/#{@get('filename')}.mp3"

    thumbnail: ->
      switch @get('type')
        when 'audio'
          if @get('student') then '/img/cassette.svg'
          else '/img/sound.svg'
        when 'video'
          @get('thumbUrl') ? @get('imageUrl') ? '/img/video.svg'
        when 'image'
          @get('thumbUrl') ? @get('imageUrl')

    icon: ->
      if (@get('type') is 'application') then @iconHash[@get('ext')] else @iconHash[@get('type')]

    match: (query, type, student)->
      re = new RegExp query,'i'
      (if student then @get('student') else true) and (type in [@get('type'),null]) and ((re.test @get('title')) or (re.test @get('tags')) or (re.test top.app.data.students.get(@get('student'))?.get('name')))

    modelType: (plural=false)->
      "file#{ if plural then 's' else ''}"


    displayTitle: ->
      "#{@get 'title'}"

    formattedSize: ->
      size = @get 'size'
      size = size / 1024
      if 0 < size < 1000 then return "#{Math.round(size*10)/10}KB"
      size = size / 1024
      if size > 0 then return "#{Math.round(size*10)/10}MB"

    formattedDuration: ->
      dur = @get('duration')
      if dur
        secs = moment.duration(dur).seconds()
        mins = moment.duration(dur).minutes()
        "#{mins}:#{if secs < 10 then '0' else ''}#{secs}"
      else "?s"


  class Collection extends Backbone.Collection
    model: Model
    syncName: 'file'

    modelType: ->
      "files"

    iconHash: {
      image: 'picture'
      video: 'play-circle'
      audio: 'volume-up'
      pdf: 'file'
      
    }

    comparator: (f)->
      0 - (moment(f.get('modified') ? 0).valueOf())

    modifiedVal: ->
      moment(@get('modified') ? 0).valueOf()


    filtered: (ui = {})->
      {term,type,student} = ui
      @filter (m)=> m.match(term ? '', type, student)

  _.extend exports, {
    Model: Model
    Collection: Collection
  }

  exports.Views = Views = {}

  class Views.MediaPlayer extends Backbone.Collection

    initialize: (@options)->

      @on 'open', =>
        @setPcEvents()

    setPcEvents: ->
      @pc?.destroy()

    template: ->
      @


    render: ->
      @$el.html ck.render @template, @
      

module 'App.File', (exports,top)->

  class Model extends Backbone.Model


    syncName: 'file'
    idAttribute: '_id'
    thumbBase: "http://s3.amazonaws.com/lingualabio-media"

    iconHash: {
      video: 'facetime-video'
      image: 'picture'
      pdf: 'file'
      audio: 'volume-up'
    }

    studentName: ->
      if @get("student")
        top.app.data.students.get(@get('student'))?.get('name')
      else null

    src: ->
      switch @get 'type'
        when 'image'
          @get 'imageUrl'
        when 'video'
          if top.Modernizr.video.webm then @get 'webmUrl'
          else if top.Modernizr.video.h264 then @get 'h264Url'
        when 'audio'
          @get 'mp3Url'

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

    match: (query)->
      re = new RegExp query,'i'
      (re.test @get('title')) or (re.test @get('tags')) or (re.test top.app.data.students.get(@get('student'))?.get('name'))

    modelType: (plural=false)->
      "file#{ if plural then 's' else ''}"


    displayTitle: ->
      "#{@get 'title'})"

      
    isSelected: ->
      @get 'selected'

    toggleSelect: ->
      @set 'selected', not @get('selected')


  class Collection extends Backbone.Collection
    model: Model
    syncName: 'file'

    comparator: (f)->
      1/moment(f.get('modified')).valueOf()

    modifiedVal: ->
      moment(@get('modified')).valueOf()

    allTags: ->
      _.union _.flatten @map (m)-> m.get('tags')?.split('|') ? []

    filteredBy: (searchTerm)->
      @filter (m)->
        re = new RegExp searchTerm, 'i'
        re.test m.get('title')

    recUploads: (request)->
      if request
        @filter (m)-> m.get('request') is request
      else
        []

    recUploadsForStudent: (id)->
      @filter (m)-> m.get('student') is id

    fromDB: (data)->
      {method, model, options} = data
      console.log 'updating ',model
      switch method
        when 'create'
          @add model
        when 'update'
          @get(model._id).set model
        when 'progress'
          console.log 'setting: ',model #change this to set only progress, otherwise new data gets overridden
          @get(model._id).set model
        when 'status'
          @get(model._id).set(model)

    modelType: ->
      "files"

    initialize: ->
      @on 'reset', =>
        if @_selected then @get(id).toggleSelect() for id in @_selected

    selected: ->
      @filter (s)-> s.isSelected()

    selectionState: ->
      if @selectedFiltered().length is @filtered().length then selState = 'all'
      else if @selectedFiltered().length is 0 then selState = 'none'
      else selState = 'some'
      selState

    filtered: ->
       @filter (m)=> m.match(@searchTerm ? '')

    selectedFiltered: ->
      _.filter @filtered(), (m)-> m.get('selected') is true

    selectFiltered: (setTo = true)->
      for student in @filtered()
        student.set 'selected', setTo

    toggleSelectFiltered: ->
      if @selectedFiltered().length is @filtered().length
        @selectFiltered false
      else if @selectedFiltered().length is 0
        @selectFiltered true
      else
        @selectFiltered false
    

  # a state model for the main view
  class UIState extends Backbone.Model
    defaults:
      searchTerm: ''
      currentListView: 'list'
      adding: false


  exports.Views = Views = {}


  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'files-main container'

    selectIcons:
      'all':'check'
      'none':'check-empty'
      'some':'reorder'

    selectStrings:
      'all':'Unselect all'
      'none':'Select all'
      'some':'Unselect all'

    initialize: ->
      @state = new UIState

      @searchBox = new top.App.Teacher.Views.SearchBox { collection: @collection }

      @searchBox.on 'change', (v)=>
        @collection.searchTerm = v
        @renderControls()
        @renderList()

      @collection.on 'reset', @render, @

      @collection.on 'add', (i) => @addItem i, true

    events:
      'click .record-video':'recordVideo'

      'click .upload-google-drive': -> @uploadFromCloud(filepicker.SERVICES.GOOGLE_DRIVE)
      'click .upload-box': -> @uploadFromCloud(filepicker.SERVICES.BOX)
      'click .upload-drop-box': -> @uploadFromCloud(filepicker.SERVICES.DROPBOX)
      'click .upload-computer': -> @uploadFromCloud(filepicker.SERVICES.COMPUTER)
      'click .upload-instagram': -> @uploadFromCloud(filepicker.SERVICES.INSTAGRAM)
      'click .upload-flickr': -> @uploadFromCloud(filepicker.SERVICES.FLICKR)
      'click .upload-url': -> @uploadFromCloud(filepicker.SERVICES.URL)
      'click .upload-find-images': -> @uploadFromCloud(filepicker.SERVICES.IMAGE_SEARCH)

      'click .delete-students': ->
        dc = new UI.ConfirmDelete { collection: @collection }
        dc.render().open()

      'click .toggle-select-all': ->
        @collection.toggleSelectFiltered()

    controlsTemplate: ->
      div class:'btn-toolbar span12', ->
        div class:'btn-group pull-left', ->
          button class:"btn btn-mini pull-left icon-#{@selectIcons[selState = @collection.selectionState()]} toggle-select-all", " #{@selectStrings[selState]}"
        
        button class:'btn btn-mini stats', "#{@collection.filtered().length} files shown, #{@collection.selected().length} selected"

        div class:'btn-group pull-right', ->
          a rel:'tooltip', 'data-toggle':'dropdown', 'data-original-title':'Upload files from your computer or services like Box, DropBox or Google Drive', class:'btn btn-mini btn-success dropdown-toggle icon-cloud', href:'#', ->
            text ' Upload from... '
            span class:'caret'
          ul class:'dropdown-menu', ->
            li -> a href:"#", class:'upload-computer ', ->
              i class:'sbicon-home'
              text ' Your computer'
            li -> a href:"#", class:'upload-box ', ->
              i class:'sbicon-box'
              text ' Box'
            li -> a href:"#", class:'upload-google-drive ', ->
              i class:'sbicon-gdrive'
              text ' Google Drive'
            li -> a href:"#", class:'upload-drop-box ', ->
              i class:'sbicon-dropbox'
              text ' Dropbox'
            li -> a href:"#", class:'upload-instagram ', ->
              i class:'sbicon-instagram'
              text ' Instagram'
            li -> a href:"#", class:'upload-flickr ', ->
              i class:'sbicon-flickr'
              text ' Flickr'
            li -> a href:"#", class:'upload-url ', ->
              i class:'icon-globe'
              text ' A specific URL'

        div class:'btn-group pull-right', ->
          a rel:'tooltip', 'data-toggle':'dropdown', 'data-original-title':'Find images and videos on the internet', class:'btn btn-mini btn-info dropdown-toggle icon-search', href:'#', ->
            text ' Find ... '
            span class:'caret'
          ul class:'dropdown-menu', ->
            li -> a href:'#', class:'upload-find-videos', ->
              i class:'sbicon-youtube'
              text ' videos'
            li -> a href:"#", class:'upload-find-images ', ->
              i class:'icon-picture'
              text ' images'

        div class:'btn-group pull-right', ->
          button rel:'tooltip', 'data-original-title':'You can record a video right from here!', class:'btn btn-mini btn-inverse record-video icon-facetime-video', ' Record a video'
   
        if @collection.selected().length

          div class:'btn-group pull-left', ->


          div class:'btn-group pull-right', ->
            button class:'btn btn-mini btn-danger icon-trash delete-students', ' Delete'
        

    template: ->
      div class:'message-cont', ->
      div class:'controls-cont row', ->
      table class:'list-cont table table-hover table-condensed', ->
        thead class:'new-item-cont'
        tbody class:'list', ->

    addItem: (file,prepend=false)->
      if @collection.length is 1 then @msg?.remove()
      v = new Views.ListItem { model: file, collection: @collection }
      v.render()
      if prepend
        v.$el.prependTo @$('.list')
      else
        v.$el.appendTo @$('.list')

      file.on 'change:selected', @renderControls, @

    fpServices:
      'record a video':
        service: filepicker.SERVICES.VIDEO
        icon: 'facetime-video'

    uploadFromCloud: (service)->
      window.filepicker.getFile '*/*', {
        modal: true
        persist: false
        services: [ service ]
        metadata: true
      }, (url, data)=>
        console.log data
        @collection.create new Model { 
          title: data.filename
          filename: data.filename
          size: data.size
          type: data.type.split('/')[0]
          mime: data.type
          fpUrl: url
        }

    recordVideo: ->
      window.filepicker.getFile '*/*', {
        modal: true
        persist: false
        services: [ filepicker.SERVICES.VIDEO ]
        metadata: true
      }, (url, data)=>
        console.log data
        @collection.create new Model { 
          title: data.filename
          filename: data.filename
          size: data.size
          type: data.type.split('/')[0]
          mime: data.type
          fpUrl: url
        }

    uploadFromComputer: (service)->
      window.filepicker.getFile '*/*', {
        modal: true
        persist: false
        services: [ filepicker.SERVICES.COMPUTER ]
        metadata: true
      }, (url, data)=>
        console.log data
        @collection.create new Model { 
          title: data.filename
          filename: data.filename
          size: data.size
          type: data.type.split('/')[0]
          mime: data.type
          fpUrl: url
        }

    handleFileUpload: ->
      console.log $('.file-picker-url').val()

    renderControls: ->
      @$('.controls-cont').html ck.render @controlsTemplate, @
      @

    renderList: ->
      @$('.list').empty()
      for file in @collection.filtered() ? @collection.models
        @addItem file

    render: ->
      @$el.html ck.render @template, @
      if not @collection.length
        @msg = new UI.Alert {
          message: 'You have no media files to use for your activities! Click the green Add button below to get started.'
        }
        @msg.render().open @$('.message-cont')

      @renderList()
      @renderControls()
      @$('button').tooltip {
        placement: 'bottom'
      }

      @searchBox.render()

      @delegateEvents()
      @

  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'list-item'

    initialize: ->
      
      @tags = new UI.TagsModal { tags: @model.get('tags') }

      @tags.on 'change', (arr,str)=>
        @model.save { tags: str }
      

      @model.on 'change:prepProgress', => @renderThumb()
      
      @model.on 'change:selected', =>
        @$('.select-item')
          .toggleClass('icon-check',@model.isSelected())
          .toggleClass('icon-check-empty',not @model.isSelected())
        @$el.toggleClass('info',@model.isSelected())

      @model.on 'remove', => @remove()
      
    events:
      'change .title': (e)->
        @model.save { title: $(e.target).val() }

      'click .download-item': 'downloadItem'

      'click .select-item': -> @model.toggleSelect()

      'click .delete-item': ->
        dc = new UI.ConfirmDelete { model: @model }
        dc.render().open()

      'click .tags-list': ->
        tm = new UI.TagsModal { 
          tags: @model.get('tags'), 
          label: @model.get('title') 
          typeahead: app.tagList()
        }
        tm.render()
        tm.on 'change', (arr,str)=>
          @model.save 'tags', str
          @render()


    thumbTemplate: ->
      if @get('status') isnt 'finished'
        div 'processing'
        div class:'progress progress-striped active', ->
          div class:'bar', style:"width: #{@get 'prepProgress' or 5}%"
      else 
        if @thumbnail()
          img src:"#{@thumbnail()}", class:'thumb'
        else
          i class:"icon-#{@icon()} icon-large"

    template: ->
      urls = @get('urls')
      td  ->
        i class:"#{ if @isSelected() then 'icon-check' else 'icon-check-empty' } select-item"
      td class:'thumb-cont', -> 
        
      td -> 
        div input class:'title span3', value:"#{ @get('title') }"
        if (studentName = @studentName())
          span class:'student icon-user', " #{ studentName }"
        span class:'tags-list span3', ->
          if @get('tags')
            span class:'pull-left icon-tags'
            for tag in @get('tags')?.split('|')
              span class:'tag', " #{tag}"
          else span class:'icon-tags', " +tags"

        

      td "#{moment(@get('modified')).fromNow()}"
      td ->
        span class:'btn-group', ->
          button rel:'tooltip', class:'btn btn-mini download-item icon-share', 'data-original-title':'download to your computer or another storage service'
          button rel:'tooltip', class:'btn btn-mini delete-item icon-trash', 'data-original-title':'delete this file'
          


    deleteItem: ->
      @model.destroy()

    downloadItem: ->
      filepicker.saveAs @model.src(), @model.get('mime'), (url)=>
        console.log 'saved'
        #@collection.create new Model { title: data.filename, filename: data.filename, size: data.size, type: data.type.split('/')[0], mime: data.type, fpUrl: url }

    renderThumb: ->
      @$('.thumb-cont').html ck.render @thumbTemplate, @model

    render: ->
      @delegateEvents()
      super()
      @renderThumb()
      @$('button').tooltip {
        placement: 'bottom'
      }
      @

  [exports.Model,exports.Collection, exports.UI] = [Model, Collection, UI]

  

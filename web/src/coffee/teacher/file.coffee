
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
      @get('thumbUrl') ? @get('imageUrl') ? 'http://placehold.it/100x100'

    icon: ->
      if (@get('type') is 'application') then @iconHash[@get('ext')] else @iconHash[@get('type')]

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'file'

    initialize: ->

    comparator: ->
      0 - moment(@get 'modified').valueOf()

    filteredBy: (searchTerm)->
      @filter (m)->
        re = new RegExp searchTerm, 'i'
        re.test m.get('title')

    fromDB: (data)->
      {method, model, options} = data
      console.log 'updating ',model
      switch method
        when 'create'
          @add model
        when 'update'
          @get(model._id).set model
        when 'progress'
          @get(model._id).set {
            prepProgress: model.prepProgress
            status: model.status
          }
        when 'status'
          @get(model._id).set(model)
    

  # a state model for the main view
  class UIState extends Backbone.Model
    defaults:
      searchTerm: ''
      currentListView: 'list'


  exports.Views = Views = {}


  # main file view, controls other list/browse sub-views
  class Views.Main extends Backbone.View
    tagName: 'div'
    className: 'files-main'

    initialize: ->
      @listView = new Views.List { collection: @collection }


      @ui = new UIState()

      @collection.on 'reset', =>
        @renderList()


      # when the searchTerm changes, do the search on the current list view
      @ui.on 'change:searchTerm', (ui,term)=>
        @listView.doSearch(term)


    events:
      'click .select-browser-view': -> @ui.set 'currentListView', 'browser'
      'click .select-list-view': -> @ui.set 'currentListView', 'list'

      'keyup .search-query': 'search'
      'click .record-upload': 'openRecorder'
      'click .file-picker': 'openFilePicker'

    search: (e)->
      clearTimeout @searchWait
      @searchWait = wait 200, => @ui.set 'searchTerm', $(e.target).val()


    template: ->
          
      div class:'row files-top-bar', ->
        span class:'btn-toolbar span4', ->
          div class:'input-prepend', ->
            span class:'add-on icon-search'
            input class:'search-query span3', type:'text', placeholder:'search'
        span class:'btn-toolbar span8 pull-right', ->
          button class:'btn btn-success icon-plus file-picker pull-right', ' Add a file'

        
      div class:'files-list-cont span10', ->
      div class:'file-detail-cont'

    openFilePicker: ->
      window.filepicker.getFile '*/*', { modal: true, persist: false, location: filepicker.SERVICES.COMPUTER }, (url,data)=>
        console.log url, data
        @collection.create new Model { title: data.filename, filename: data.filename, size: data.size, type: data.type.split('/')[0], mime: data.type, fpUrl: url }
      wait 1000, ->
        $('<button></button>').addClass('btn').text('hello').appendTo @$('#filepicker_dialog_container')

    handleFileUpload: ->
      console.log $('.file-picker-url').val()

    openRecorder: ->
      @recorder?.remove()
      @recorder ?= new Views.Recorder()
      @recorder.render().open()
      @

    renderList: ->
      @listView.render().open @$('.files-list-cont')
      @

    render: ->
      @$el.html ck.render @template, @
      @renderList()

      @$('.tt').tooltip()


      # fix the top search bar on scroll down
      @$('.files-top-bar').removeClass('navbar-fixed-top').waypoint (event,direction)=>
        if direction is 'down' then @$('.files-top-bar').hide().addClass('sticky').fadeIn()
        else @$('.files-top-bar').hide().removeClass('sticky').fadeIn()
      , { offset: 0 }

           
      @delegateEvents()
      @

  class Views.Recorder extends Backbone.View
    tagName: 'div'
    className: 'modal popup-recorder'

    template: ->
      div class:'modal-header', ->
        h2 'Record and upload your voice'
      div class:'modal-body', ->
      div class:'modal-footer', ->
        button class:'btn', ->
          text ' Nevermind'
        button class:'btn btn-success', ->
          i class:'icon-upload'
          text ' Upload it!'


    render: ->
      super()
      @recorder ?= new App.Recording.Views.Recorder()
      @recorder.render().open @$('.modal-body')
      @$el.modal('show')
      @


  # list sub-view
  class Views.List extends Backbone.View
    tagName: 'table'
    className: 'table file-list'

    initialize: ->
      @collection.on 'add', @addItem


      @collection.on 'reset', => @render()


    doSearch: (@searchTerm)->
      @render()

    template: ->
      thead ->
      tbody ->
      tfoot ->
          

    addItem: (f)=>
      f.listItemView?.remove()
      f.listItemView ?= new Views.ListItem { model: f }
      f.listItemView.render().open @$('tbody')
      @
    
    render: ->
      @$el.html ck.render @template, @collection
      @addItem f for f in (if @searchTerm then @collection.filteredBy(@searchTerm) else @collection.models)

      upl = @collection.uploadFile
      input = @$('.select-upload').browseElement()
      input.on 'change', (e)->
        for f in e.target.files
          console.log 'uploading ',f
          upl f

      @delegateEvents()
      @


  # single items in a list
  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'list-item'

    initialize: ->
      @model.on 'change', => @renderThumb()
      @model.on 'remove', => @remove()

    events:
      'change .title': (e)->
        @model.save({ title: $(e.target).val() })
      'click .delete': 'deleteItem'
      'click .dl': 'downloadItem'
      'dblclick': -> @model.collection.trigger 'selected', @model


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
      td class:'thumb-cont', -> 
        
      td -> input class:'title', value:"#{ @get('title') }"
      td moment(@get('created')).format("MMM D h:mm:ss a")
      td class:'tags-cont', -> 
      td -> i class:'icon-share-alt dl'
      td -> i class:'icon-trash delete'


    deleteItem: ->
      @model.destroy()

    downloadItem: ->
      filepicker.saveAs @model.src(), @model.get('mime'), (url)->
        console.log url

    renderThumb: ->
      @$('.thumb-cont').html ck.render @thumbTemplate, @model

    render: ->
      @delegateEvents()
      super()
      @renderThumb()
      @


  class Views.Detail extends Backbone.View
    tagName: 'div'
    className: 'file-video-detail'

    template: ->
      switch @get 'type'
        when 'video'
          video class:'video',src:"#{@src()}"
        when 'image'
          img src:"#{@src()}"
 

  [exports.Model,exports.Collection, exports.UI] = [Model, Collection, UI]


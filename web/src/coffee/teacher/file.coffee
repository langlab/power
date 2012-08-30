
module 'App.File', (exports,top)->

  class Model extends Backbone.Model


    syncName: 'file'
    idAttribute: '_id'
    thumbBase: "http://s3.amazonaws.com/lingualabio-media"

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

    match: (query, type, student)->
      re = new RegExp query,'i'
      log student
      (if student then @get('student') else true) and (type in [@get('type'),null]) and ((re.test @get('title')) or (re.test @get('tags')) or (re.test top.app.data.students.get(@get('student'))?.get('name')))

    modelType: (plural=false)->
      "file#{ if plural then 's' else ''}"


    displayTitle: ->
      "#{@get 'title'})"


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

      
    isSelected: ->
      @get 'selected'

    toggleSelect: ->
      @set 'selected', not @get('selected')


  class Collection extends Backbone.Collection
    model: Model
    syncName: 'file'

    initialize: ->
      @on 'reset', =>
        if @_selected then @get(id).toggleSelect() for id in @_selected

      @type ?= null
      @student ?= null
      @term ?= ''

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

    allTags: ->
      _.union _.flatten @map (m)-> m.get('tags')?.split('|') ? []

    filteredBy: (term)->
      @filter (m)->
        re = new RegExp term, 'i'
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



    selectionState: ->
      if @selectedFiltered().length is @filtered().length then selState = 'all'
      else if @selectedFiltered().length is 0 then selState = 'none'
      else selState = 'some'
      selState

    filtered: (ui = {})->
      {term,type,student} = ui
      @filter (m)=> m.match(term ? '', type, student)

    selectedFiltered: (ui)->
      _.filter @filtered(ui), (m)-> m.id in ui.selected

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
      term: ''
      currentListView: 'list'
      adding: false


  exports.Views = Views = {}


  class Views.ModalSelector extends Backbone.View
    tagName: 'div'
    className: 'modal fade hide file-selector'

    initialize: (@options)->

      @on 'open', =>
        @$el.modal 'show'

      @$el.on 'hidden', =>
        @remove()

    template: ->
      div class:'modal-body', ->
        div class:'navbar', ->
          div class:'navbar-inner', ->

        table class:'table table-hover table-condensed', ->



    close: ->
      @$el.modal 'hide'


  class Views.Detail extends Backbone.View
    tagName: 'div'
    className: 'file-detail container buffer-top'

    initialize: (@options)->

    template: ->
      div class:'row-fluid', ->

        div class:'span8', ->
          switch @model.get('type')
            when 'video'
              video src:"#{@model.src()}", controls:'true', class:'span12'
            when 'audio'
              audio src:"#{@model.src()}", controls:'true', class:'span12'
            when 'image'
              img src:"#{@model.src()}", class:'span12'

        div class:'span3', ->

    render: ->
      @$el.html ck.render @template, @options
      @

    



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
      @state = new UIState {
        term: ''
        student: null
        type: null
        show: 30
        page: 0
        selected: []
      }

      @searchBox = new top.App.Teacher.Views.SearchBox { collection: @collection }

      @searchBox.on 'change', (v)=>
        @state.set 'term', v


      @collection.on 'reset', @render, @

      @collection.on 'add', (i) => @addItem i, true

      @state.on 'change:selected', =>
        @renderControls()

      @state.on 'change:term', =>
        @renderControls()
        @renderList()

      @state.on 'change:type', =>
        @renderControls()
        @renderList()

      @state.on 'change:student', =>
        @renderControls()
        @renderList()

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

      'click .toggle-select-all': 'toggleSelectFiltered'

      'click .filter-by-type button': (e)->
        @$(e.currentTarget).tooltip('hide')
        type = $(e.currentTarget).attr('data-filter')
        if @state.get('type') is type
          @state.set 'type', null
        else
          @state.set 'type', (if type is 'all' then null else type)


      'click .filter-by-student button': (e)->
        @$(e.currentTarget).tooltip('hide')
        @state.set 'student', not @state.get('student')

    toggleSelectFiltered: ->
      ui = @state.toJSON()
      log 'selecting all'
      if @collection.selectedFiltered(ui).length is @collection.filtered(ui).length
        @selectFiltered false
      else if @collection.selectedFiltered(ui).length is 0
        @selectFiltered true
      else
        @selectFiltered false


    selectFiltered: (sel = true)->
      ui = @state.toJSON()
      filtered = _.pluck(@collection.filtered(ui),'id')
      selected = @state.get('selected')
      log selected,filtered

      if sel
        @state.set 'selected', _.union(filtered, selected)
      else
        @state.set 'selected', _.difference(selected, filtered)

      @state.trigger 'change:selected'

    controlsTemplate: ->

      div class:'btn-toolbar span12', ->


        div class:'btn-group pull-left', ->
          button class:"btn btn-mini pull-left icon-#{@selectIcons[selState = @collection.selectionState()]} toggle-select-all", " #{@selectStrings[selState]}"
        
        button class:'btn btn-mini stats', "#{@collection.filtered(@state.toJSON()).length}#{if (f = @state.get('type')) then " "+f else ''} files #{if @state.get('student') then 'by students ' else ''}shown, #{@state.get('selected').length} selected"

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
            li -> a href:"#", class:'upload-find-images ', ->
              i class:'icon-picture'
              text ' Public web images'
            li -> a href:"#", class:'upload-url ', ->
              i class:'icon-globe'
              text ' A specific URL'

            

        div class:'btn-group pull-right', ->
          button rel:'tooltip', 'data-original-title':'You can record a video right from here!', class:'btn btn-mini btn-inverse record-video icon-facetime-video', ' Record a video'
   
        if @state.get('selected').length


          div class:'btn-group pull-right', ->
            button class:'btn btn-mini btn-danger icon-trash delete-students', ' Delete'


        div class:'btn-group pull-right filter-by-type', 'data-toggle':"buttons-radio", ->
          for label,icon of @collection.iconHash
            button rel:'tooltip', 'data-title':"show only #{label}", 'data-filter': "#{label}", class:"btn btn-mini icon-#{icon} filter-#{label} #{if @state.get('type') is label then 'active' else ''}"
          #button rel:'tooltip', 'data-title':'show all types', 'data-filter': "all", class:"btn btn-mini #{if not @collection.type and not @collection.student then 'active' else ''}", "All"
        
        div class:'btn-group pull-right filter-by-student', 'data-toggle':'buttons-checkbox', ->
          button rel:'tooltip', 'data-title':'show only student submissions', class:"btn btn-mini icon-user #{if @state.get('student') then 'active' else ''}"


    template: ->
      div class:'message-cont', ->
      div class:'controls-cont row', ->
      table class:'list-cont table table-hover table-condensed', ->
        thead class:'new-item-cont'
        tbody class:'list', ->
        tfoot ->
          

    addItem: (file,prepend=false)->
      if @collection.length is 1 then @msg?.remove()
      v = new Views.ListItem { model: file, collection: @collection, state: @state }
      v.render()
      if prepend
        v.$el.prependTo @$('.list')
      else
        v.$el.appendTo @$('.list')

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
        maxsize: 50*1024*1024
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
        maxsize: 50*1024*1024
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
      @$('button').tooltip {
        placement: 'top'
      }
      @

    renderList: ->
      {page,show} = ui = @state.toJSON()
      @state.set 'page', 0
      @$('.list').empty()
      list = _.first @collection.filtered(ui), show
      for file in list
        @addItem file
      @setMoreTrigger()
      

    renderMore: ->
      {page,show} = @state.toJSON()
      log page
      list = _.first _.rest(@collection.filtered(@state.toJSON()), page*show), show
      for file in list
        @addItem file
      @setMoreTrigger()


    showMoreTemplate: ->
      tr ->
        td colspan:10, -> div class:'alert alert-info show-more', "more"

    setMoreTrigger: ->
      {page,show} = ui = @state.toJSON()
      @$('tfoot').empty()
      if @collection.filtered(ui).length >= (page+1)*show
        showMoreEl = $(ck.render @showMoreTemplate)
        showMoreEl.appendTo @$('tfoot')
        wait 500, =>
          showMoreEl.waypoint {
            offset: '90%'
            handler: (ev,direction)=>
              if direction is 'down'
                @state.set 'page', 1+@state.get('page')
                @renderMore()
          }
        showMoreEl.click =>
          @state.set 'page', 1+@state.get('page')
          @renderMore()

    render: ->
      @$el.html ck.render @template, @
      if not @collection.length
        @msg = new UI.Alert {
          message: 'You have no media files to use for your activities! Click the green Add button below to get started.'
        }
        @msg.render().open @$('.message-cont')

      @renderList()
      @renderControls()
      @searchBox.render()
      wait 500, =>
        @setMoreTrigger()
      @delegateEvents()
      @

  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'list-item'

    initialize: (@options)->
      
      @tags = new UI.TagsModal { tags: @model.get('tags') }

      @tags.on 'change', (arr,str)=>
        @model.save { tags: str }
      

      @model.on 'change:prepProgress', => @renderThumb()
      
      @options.state.on 'change:selected', => @updateSelectStatus()

      @model.on 'remove', => @remove()
      
    events:
      'change .title': (e)->
        @model.save { title: $(e.target).val() }

      'dblclick .thumb-cont': ->
        if @model.get('student')
          if @model.get('type') is 'audio'
            top.app.router.navigate "/student/#{@model.get('student')}/recording/#{@model.id}", true
        else
          top.app.router.navigate "/file/#{@model.id}", true

      'click .download-item': 'downloadItem'

      'click .select-item': 'toggleSelect'

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

    updateSelectStatus: ->
      @$('.select-item')
        .toggleClass('icon-check',@isSelected())
        .toggleClass('icon-check-empty',not @isSelected())
      @$el.toggleClass('info',@isSelected())

    isSelected: ->
      @model.id in @options.state.get('selected')

    toggleSelect: ->
      if @isSelected()
        @options.state.set 'selected', _.without @options.state.get('selected'), @model.id
      else
        @options.state.get('selected').push @model.id

      @options.state.trigger "change:selected"

    thumbTemplate: ->
      if (@get('status') isnt 'finished')
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
        div class:'timestamp', ->
          if @get('student')
            div class:'recorded', "recorded #{moment(@get('created') ? (new Date())).calendar()}"
          else
            div class:'uploaded', "uploaded #{moment(@get('created') ? (new Date())).calendar()}"
            div class:'modified', "last modified #{moment(@get('modified') ? (new Date())).calendar()}"
        

      td ->
        if (studentName = @studentName())
          span class:'student icon-user', " #{ studentName }"
        span class:'tags-list span3', ->
          if @get('tags')
            span class:'pull-left icon-tags'
            for tag in @get('tags')?.split('|')
              span class:'tag', " #{tag}"
          else span class:'icon-tags', " +tags"

      td ->
        div class:'size icon-truck', " #{@formattedSize()}"
        if @get('type') in ['audio','video']
          div class:'duration icon-time', " #{@formattedDuration()}"
      
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
      @updateSelectStatus()
      @

  [exports.Model,exports.Collection, exports.UI] = [Model, Collection, UI]

  


module 'App.File', (exports,top)->

  class Model extends Backbone.Model


    syncName: 'file'
    idAttribute: '_id'
    thumbBase: "http://s3.amazonaws.com/lingualabio-media"
    baseUrl: 'https://lingualabio-media.s3.amazonaws.com'

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

    src: (dl=false)->
      base = if dl then '/dl' else @baseUrl
      switch @get 'type'
        when 'image'
          "#{base}/#{@get('filename')}.#{@get('ext')}"
        when 'video'
          if top.Modernizr.video.webm then "#{base}/#{@get('filename')}.webm"
          else if top.Modernizr.video.h264 then "#{base}/#{@get('filename')}.mp4"
        when 'audio'
          "#{base}/#{@get('filename') ? @id}.mp3"

    thumbnail: ->
      switch @get('type')
        when 'audio'
          if @get('student') then '/img/cassette.svg'
          else '/img/sound.svg'
        when 'video'
          "#{@baseUrl}/#{@get('filename')}_0004.png"
        when 'image'
          "#{@baseUrl}/#{@get('filename')}.#{@get('ext')}"

    dimensions: ->
      switch @get('type')
        when 'audio'
          { width: null, height: null }
        when 'video'
          v = $('<video/>').attr('src',@src())[0]
          { width: v.videoWidth, height: v.videoHeight }
        when 'image'
          img = new Image()
          img.src = @src()
          { width: img.width, height: img.height }

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

    initialize: ->


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
        when 'feedback'
          @get(model._id).set {
            feedback: model.feedback
          }
        when 'progress'
          console.log 'setting: ',model #change this to set only progress, otherwise new data gets overridden
          @get(model._id).set {
            prepProgress: model.prepProgress
            status: model.status
          }

        when 'status'
          @get(model._id).set(model)


    filtered: (ui = {})->
      {term,type,student} = ui
      @filter (m)=> m.match(term ? '', type, student)

    selectedFiltered: (ui)->
      _.filter @filtered(ui), (m)-> m.id in ui.selected

    

  # a state model for the main view
  class UIState extends Backbone.Model
    defaults:
      term: ''
      currentListView: 'list'
      adding: false


  exports.Views = Views = {}

  class Views.ModalListItem extends Backbone.View
    tagName: 'tr'
    className: 'modal-list-item'

    template: ->
      td class:'thumb',->
        img src:"#{@model.thumbnail()}"
      td ->
        div "#{@model.get('title')}"

    render: ->
      @$el.html ck.render @template, @options
      @

  class Views.ModalSelector extends UI.List
    tagName: 'div'
    className: 'modal fade hide file-selector'

    initialize: (@options)->
      super()

      @state.set {
        term: ''
        students: null
        type: null
      }

      @on 'open', =>

        @$el.modal 'show'

        @$el.on 'hidden', =>
          @remove()

      @state.on 'change:type', =>
        @renderList()

    events:
      #'keyup input.search-query':'doSearch'

      'click .filter-by-type button': (e)->
        @$(e.currentTarget).tooltip('hide')
        type = $(e.currentTarget).attr('data-filter')
        if @state.get('type') is type
          @state.set 'type', null
        else
          @state.set 'type', type

    doSearch: (e)->
      @state.set 'term', $(e.currentTarget).val() 
      
    template: ->
      div class:'modal-head controls-cont', ->
        
      div class:'modal-body', ->
        table class:'table table-hover table-condensed', ->
          thead ->
            tr -> td colspan:5, class:'message-cont', ->
          tbody class:'list-cont', ->

    addItem: (file,prepend=false)->
      if @collection.length is 1 then @msg?.remove()
      v = new Views.ModalListItem { model: file, collection: @collection, state: @state }
      v.render()
      console.log v
      if prepend
        v.$el.prependTo @$('.list-cont')
      else
        v.$el.appendTo @$('.list-cont')

    close: ->
      @$el.modal 'hide'
      @

    controlsTemplate: ->
      div class:'navbar', ->
        div class:'navbar-inner', ->
          div class:"brand", "Your files"
          div class:'btn-group pull-left filter-by-type', ->
            for label,icon of @collection.iconHash
              button rel:'tooltip', 'data-title':"show only #{label}", 'data-filter': "#{label}", class:"btn icon-#{icon} filter-#{label} #{if @state.get('type') is label then 'active' else ''}"
          form class:'navbar-search pull-right', ->
            input type:'text', class:'search-query', placeholder: 'search files'
    
    renderModalControls: ->    
      @$('controls-cont').html ck.render @controlsTemplate, @  
      @$('.search-query').typeahead {
        source: @collection.allTags()
      }
      @$('.search-query').on 'change', =>
        @state.set 'term', @$('.search-query').val()
      @

    renderControls: -> #just to override inherited func

    render: ->
      @$el.html ck.render @template, @

      if not @collection.length
        @msg = new UI.Alert {
          message: 'You have no media files.'
        }
        @msg.render().open @$('.message-cont')

      @renderList()

      @renderModalControls()
      @


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


  class Views.Main extends UI.List

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

    initialize: (@options)->
      super()

      @state.set 'type', null

      _.defaults @state, {
        term: ''
        student: null
        type: null
        show: 30
        page: 0
      }

      @searchBox = new top.App.Teacher.Views.SearchBox { collection: @collection }

      @searchBox.on 'change', (v)=>
        @state.set 'term', v

      @state.on 'change:type', =>
        @renderControls()
        @renderList()

      @state.on 'change:student', =>
        @renderControls()
        @renderList()

    events:
      'click .record-video':'recordVideo'
      'click .upload-google-drive': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.GOOGLE_DRIVE)
      'click .upload-box': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.BOX)
      'click .upload-drop-box': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.DROPBOX)
      'click .upload-computer': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.COMPUTER)
      'click .upload-instagram': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.INSTAGRAM)
      'click .upload-flickr': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.FLICKR)
      'click .upload-url': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.URL)
      'click .upload-find-images': (e)-> 
        e.preventDefault()
        @uploadFromCloud(filepicker.SERVICES.IMAGE_SEARCH)

      'click .delete-students': ->
        dc = new UI.ConfirmDelete { collection: @collection.getByIds(@state.get('selected')), modelType: @collection.modelType(true) }
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

    selectedFiltered: ->
      @collection.selectedFiltered(@state.toJSON())

    filtered: ->
      @collection.filtered(@state.toJSON())

    selectState: ->
      if @selectedFiltered().length is 0 then 'none'
      else if @selectedFiltered().length is @filtered().length then 'all'
      else 'some' 

    controlsTemplate: ->
      numSelectedFiltered = @selectedFiltered().length
      numFiltered = @filtered().length
      numSelected = @state.get('selected').length

      div class:'btn-toolbar span12', ->

        div class:'btn-group pull-left', ->
          button class:"btn btn-mini pull-left icon-#{ @selectIcons[@selectState()] } toggle-select-all", " #{ @selectStrings[@selectState()] }"
        
        button class:'btn btn-mini stats', "#{numFiltered}#{if (f = @state.get('type')) then " "+f else ''} files #{if @state.get('student') then 'by students ' else ''}shown, #{@state.get('selected').length} selected"

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
      table class:'list-main-cont table table-hover table-condensed', ->
        thead class:'new-item-cont'
        tbody class:'list-cont', ->
        tfoot ->
          tr ->
            td colspan:10, class:'show-more-cont', ->
          

    addItem: (file,prepend=false)->
      if @collection.length is 1 then @msg?.remove()
      v = new Views.ListItem { model: file, collection: @collection, state: @state }
      v.render()
      if prepend
        v.$el.prependTo @$('.list-cont')
      else
        v.$el.appendTo @$('.list-cont')

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
          title: "Video Recording #{moment().format("YYYY-MMM-D")}"
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

    
    render: ->
      @$el.html ck.render @template, @
      if not @collection.length
        @msg = new UI.Alert {
          message: 'You have no media files to use for your activities! Click the green upload button above to get started.'
        }
        @msg.render().open @$('.new-item-cont')

      @searchBox.render()
      @state.set 'term', ''
      @renderList()
      @renderControls()
      wait 500, =>
        @setMoreTrigger()
      @delegateEvents()
      @

  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'file-list-item list-item'

    initialize: (@options)->
      
      @tags = new UI.TagsModal { tags: @model.get('tags') }

      @tags.on 'change', (arr,str)=>
        @model.save { tags: str }
      

      @model.on 'change:prepProgress', => @renderThumb()

      @model.on 'change:status', => @renderThumb()
      
      @options.state.on 'change:selected', => @updateSelectStatus()

      @model.on 'remove', => @remove()
      
    events:
      'change .title': (e)->
        @model.save { title: $(e.target).val() }

      'click .thumb-cont, .detail': ->
        if @model.get('student')
          if @model.get('type') is 'audio'
            top.app.router.navigate "/student/#{@model.get('student')}/recording/#{@model.id}", true
        else
          top.app.router.navigate "/file/#{@model.id}", true


      'click .select-item': 'toggleSelect'

      'click .delete-item': ->
        dc = new UI.ConfirmDelete { collection: [@model], modelType: @model.collection.modelType(true) }
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
      urls = @model.get('urls')
      td  ->
        i class:"#{ if @isSelected() then 'icon-check' else 'icon-check-empty' } select-item"
      td class:"thumb-cont #{@model.get('type')}", -> 
        
      td -> 
        div input class:'title span3', type:'text', value:"#{ @model.get('title') }"
        div class:'timestamp', ->
          if @model.get('student')
            div class:'recorded', "recorded #{moment(@model.get('created') ? (new Date())).calendar()}"
          else
            div class:'uploaded', "uploaded #{moment(@model.get('created') ? (new Date())).calendar()}"
            div class:'modified', "last modified #{moment(@model.get('modified') ? (new Date())).calendar()}"
        

      td ->
        if (studentName = @model.studentName())
          span class:'student icon-user', " #{ studentName }"
        span class:'tags-list span3', ->
          if @model.get('tags')
            span class:'pull-left icon-tags'
            for tag in @model.get('tags')?.split('|')
              span class:'tag', " #{tag}"
          else span class:'icon-tags', " +tags"

      td ->
        div class:'size icon-truck', " #{@model.formattedSize()}"
        if @model.get('type') in ['audio','video']
          div class:'duration icon-time', " #{@model.formattedDuration()}"
      
      td ->
        span class:'btn-group', ->
          button rel:'tooltip', title:'open/view this file', class:'btn btn-mini icon-share-alt detail-view'
          a rel:'tooltip', title:'download this file', class:"btn btn-mini icon-download-alt download-item", href:"#{@model.src(true)}", target:'_blank', ->
          button rel:'tooltip', class:'btn btn-mini delete-item icon-trash', 'data-original-title':'delete this file'
          


    deleteItem: ->
      @model.destroy()


    renderThumb: ->
      @$('.thumb-cont').html ck.render @thumbTemplate, @model

      @

    render: ->
      @$el.html ck.render @template, @
      @renderThumb()
      @$('button, a').tooltip {
        placement: 'bottom'
      }
      @updateSelectStatus()
      @

  [exports.Model,exports.Collection, exports.UI] = [Model, Collection, UI]

  

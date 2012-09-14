module 'UI', (exports,top)->

  class UIState extends Backbone.Model

  class Alert extends Backbone.View
    tagName: 'div'
    className: 'alert fade in'

    initialize: (@options)->
      _.defaults @options, {
        type: 'info' # warning, danger, success
        close: false
        icon: 'info-sign'
        message: 'Message'
      }


    render: ->
      {type,close,icon,message} = @options
      @$el.addClass "alert-#{type}"
      @$el.addClass "icon-#{icon}"
      @$el.html " "+message
      if close then @$el.append $('<a class="close" data-dismiss="alert" href="#">&times;</a>')
      @

  class Slider extends Backbone.View
    tagName: 'div'
    className: 'slider-cont'

    initialize: (@options)->
      @options ?= {}
      _.defaults @options, {
        min: 0
        max: 100
        handleWidthPerc: 0   #if 0, width will default to height of the groove
      }

    template: ->
      div class:'slider-groove', -> 
        div class:'slider-handle icon-caret-up'


    renderMarkAt: (markVal)->
      $('<div/>')
        .addClass('slider-mark')
        .css('left',((mark - @options.min)/(@options.max-@options.min) * @grooveW()))
        .appendTo @$('.slider-groove')

    addMarkAt: (markVal)->
      marks.push markVal
      @renderMarkAt markVal

    renderMarks: ->
      @$('.slider-grove .slider-mark').remove()
      for mark in @marks
        @renderMarkAt(mark)


    render: ->
      @$el.html ck.render @template
      @on 'open', ->
        @groove = @$('.slider-groove')
        @handle = @$('.slider-handle')
        @setHandleWidthPerc (@options.handleWidthPerc*@grooveW()/100)
      @

    events:
      'mousedown':'startDrag'
      'mouseup':'stopDrag'
      'mousemove':'drag'

    handleW: ->
      @handle.width()

    handleX: ->
      @handle.position().left


    getVal: ->
      @options.min + (@handleX() / @grooveW()) * (@options.max - @options.min)

    setVal: (v)->
      @setSliderX ((v - @options.min)/(@options.max-@options.min) * @grooveW()), true
      @

    grooveW: ->
      @groove.width() - @handleW()

    setHandleWidthPerc: (perc)->
      @handle.width (perc*@grooveW()/100) or 8

    setSliderX: (x,silent=false)->
      # console.log @handleW(), @grooveW(), x
      x = x - (@handleW()/2)
      x = if x < 0 then 0 else if x > @grooveW() then @grooveW() else x
      @$('.slider-handle').css 'left', x
      if not silent
        @trigger 'change', @getVal()
      @

    startDrag: (e)->
      targetOffsetX = if $(e.target).hasClass('slider-handle') then @handleX() else 0
      newX = 4 + e.offsetX + targetOffsetX
      @setSliderX newX
      @dragging = true
      @

    stopDrag: (e)->
      @dragging = false
      @

    drag: (e)->
      targetOffsetX = if $(e.target).hasClass('slider-handle') then @handleX() else 0
      newX = e.offsetX + targetOffsetX
      if @dragging then @setSliderX newX
      @

  class MediaScrubber extends Backbone.View
    tagName: 'div'
    className:'ui-media-scrubber'

    initialize: (@options={})->
      _.defaults @options, {
        animation: "jump"
        min: 0
        max: 100
        hideInput: true
        step: 1
        precision: 0
      }

      @on 'open', =>
        _.extend @options, {
          inp: @$('.scrubber-input')[0]
          callbacks:
            change: [(obj)=> @triggerChange obj.value]
        }

        fdSlider.createSlider @options



    triggerChange: (val)->
      console.log val
      if not @silent then @trigger 'change', val
      @silent = false

    template: ->
      input id:"#{@id = moment().valueOf()}", class:'scrubber-input'

    render: ->
      @$el.html ck.render @template, @
      @

    increment: (steps)->
      fdSlider.increment @id, steps

    setVal: (val, silent=true)->
      @silent = silent
      stepDiff = Math.round (val - @$('.scrubber-input').val())/@options.step
      @increment stepDiff

    destroy: ->
      fdSlider.destroySlider @id


        
        
  
  class IncDec extends Backbone.View
    tagName: 'div'
    className: 'inc-dec'

    initialize: (@options)->
      console.log @options
      @_val = @options?.val ? 0

      @on 'change'

    events:
      'click .inc': 'inc'
      'click .dec': 'dec'


    template: ->
      input class:'span1', type:'text', value:"#{@val()}"
      div class:'btn-toolbar btn-toolbar-vertical', ->
        div class:'btn-group-vertical btn-group', ->
          button class:'btn icon-plus inc'
          button class:'btn icon-minus dec'

    inc: ->
      if (not @options?.max) or (@_val+1 < @options.max) then @val @_val+1

    dec: ->
      if (not @options?.min) or (@_val-1 < @options.min) then @val @_val-1

    val: (v)->
      if v 
        @_val = v
        @trigger 'change', @_val
        @
      else @_val


  class ConfirmDelete extends Backbone.View
    tagName: 'div'
    className: 'modal fade hide'

    events:
      'click .delete': ->
        for model in @collection
          model.destroy()
        @$el.modal('hide')
        @$el.on 'hidden', => @remove()

    initialize: (@options)->
      @collection.modelType = @options.modelType

    template: ->
      div class:'modal-header', ->
        h3 'Are you sure?'
      div class:'modal-body', ->
        if @length > 1
          p "You are about to delete #{ @length } #{ @modelType }:"
          ul ->
            for model in @
              li "#{model.displayTitle()}"
         
        else
          p "You are about to delete: #{@[0].displayTitle()}"
          

      div class:'modal-footer', ->
        button class:'btn cancel', 'data-dismiss':'modal', "No, don't do it"
        button class:'pull-right btn btn-danger icon-trash icon-large delete', ' DELETE PERMANENTLY'

    render: ->
      @$el.html ck.render @template, @collection
      @$el.modal()
      @

  class FlashMessage extends Backbone.View
    tagName:'span'
    className:'alert'

    initialize: (options)->
      _.defaults options, {
        message: 'hi'
        type: 'success'
        time: 2000
        cont: 'body'
      }

      _.extend @, options

    render: ->
      @$el.text @message
      @$el.addClass "alert-#{@type}"
      @$el.appendTo @cont
      
      if @time
        wait @time, => @remove()


  class HtmlEditor extends Backbone.View
    tagName: 'div'
    className: 'html-editor'

    initialize: (options)->

      @on 'open', =>
        @trigger 'ready'
        @$('.editor-area').attr('contenteditable',true)
        @$('.editor-area').html options?.html or ''
        @$('.editor-area').focus()

      
    document: document

    events:
      'click .bold': 'bold'
      'click .italic': 'italic'
      'click .underline': 'underline'
      'click .link':'link'
      'click .size':'size'
      'click .insert-input':'insertInput'
      'click .insert-table':'insertTable'
      'click .insert-media':'insertMedia'



    simplifiedHTML: ->
      body = @$('.editor-area').html()
      #body = body.replace /<span class=.template-field. data-fld=.([^"]+).>[^<]*<\/span>/g, "{$1}"
      #console.log body
      body

    getSelectedText: ->
      if @document?.selection
        document.selection.createRange().text
      else if @document
        document.getSelection().toString()

    selectTest: ->
      if @getSelectedText().length is 0
        alert 'Select some text first.'
        return false
      true

    exec: (type, arg = null) ->
      @document.execCommand(type, false, arg)

    query: (type) ->
      @document.queryCommandValue(type)

    bold: (e) ->
      e.preventDefault()
      @exec 'bold'

    italic: (e) ->
      e.preventDefault()
      @exec 'italic'

    underline: (e)->
      e.preventDefault()
      @exec 'underline'

    list: (e) ->
      e.preventDefault()
      @exec 'insertUnorderedList'

    insertInput: (e)->
      console.log e.currentTarget
      e.preventDefault()
      #fld = $(e.currentTarget).attr('data-fld')
      #label = $(e.currentTarget).attr('data-label')
      @exec 'insertHTML', "&nbsp;<input type='text' class='input-min' placeholder='hi'></input>&nbsp;"

    insertTable: (e)->
      console.log e.currentTarget
      e.preventDefault()
      #fld = $(e.currentTarget).attr('data-fld')
      #label = $(e.currentTarget).attr('data-label')
      @exec 'insertHTML', "&nbsp;<table class='table table-condensed table-bordered'><tr><td>1</td><td>2</td></tr></table>&nbsp;"

    imgTemplate: ->
      img src:'https://lingualabio-media.s3.amazonaws.com/504779434239b852a000001c.jpeg'
      span contenteditable:"false", class:'timg', style:'border: 1px solid #333', ->
        text " This should not be editable "
      text "&nbsp;"

    insertMedia: (e)->
      e.preventDefault()
      @exec 'insertHTML', ck.render @imgTemplate, @
      @$('.timg').attr('contenteditable',false)

    link: (e) ->
      e.preventDefault()
      @exec 'unlink'
      href = prompt('Enter a link:', 'http://')
      return if not href or href is 'http://'
      href = 'http://' + href  unless (/:\/\//).test(href)
      @exec 'createLink', href

    size: (e)->
      e.preventDefault()
      @exec 'fontSize', $(e.target).attr('data-size')

    loadTemplate: (e)->
      e.preventDefault()
      @$('.editor-area').html @templates[$(e.currentTarget).attr('data-template')]

    template: ->
      div class:'wb-header', ->
        div class:'btn-toolbar', ->
          div class:'btn-group pull-right right-group', ->
            
          div class:'btn-group pull-left left-group', ->
            button class:'btn btn-mini icon-bold bold'
            button class:'btn btn-mini icon-italic italic'
            button class:'btn btn-mini icon-underline underline'
            button class:'btn btn-mini icon-link link'
            a class:"btn btn-mini dropdown-toggle icon-text-height", 'data-toggle':"dropdown", href:"#", ->
              span class:'caret'
            ul class:'dropdown-menu', ->
              li -> a href:'#', class:'size', 'data-size':2, 'small'
              li -> a href:'#', class:'size', 'data-size':4, 'medium'
              li -> a href:'#', class:'size', 'data-size':5, 'large'
            button class:'btn btn-mini icon-question-sign insert-input'
            button class:'btn btn-mini icon-table insert-table'
            button class:'btn btn-mini icon-play-circle insert-media'

      div class:'wb-body', ->
        div class:'editor-area',  ->

    render: ->
      @$el.html ck.render @template, @options
      @$('.editor-area').html ''
      @
  

  class TagsModal extends Backbone.View
    tagName: 'div'
    className: 'ui-tags-modal modal hide fade'

    initialize: (@options)->
      _.defaults @options, {
        tags: []
        label: 'this item'
        typeahead: []
      }

      @tags = new Tags { 
        tags: @options.tags 
        typeahead: @options.typeahead
      }

      @tags.on 'change', (arr,str)=>
        @trigger 'change', arr, str

    events:
      'click .done': -> 
        @$el.modal('hide')
         

    template: ->
      div class:'modal-header', ->
        h2 "Tags for #{@label}"
      div class:'modal-body', ->
        p "Enter some tags that describe #{@label}:"
        div class:'ui-tags-control-cont', ->

      div class:'modal-footer', ->
        button class:'btn btn-success icon-ok done', " Done"

    render: ->
      @$el.html ck.render @template, @options
      @$el.modal('show')
      @$el.on 'shown', =>
        @$('input').focus()
      @tags.render().open @$('.ui-tags-control-cont')
      @delegateEvents()
      @$el.on 'hidden', =>
        @remove()
      @


  class Tags extends Backbone.View
    tagName: 'div'
    className: 'ui-tags'

    initialize: (@options)->
      _.defaults @options, {
        tags: []
        typeahead: ['one','two','three','four']
      }

      @reset @options.tags

    tagsTemplate: ->
      span class:'icon-tags pull-left' 
      console.log @_tags, @getArray(),@getString()
      for tag in @getArray()
        span class:'tag', tag

    renderTags: ->
      @$('.ui-tags-cont').html ck.render @tagsTemplate, @

    template: ->
      div class:'ui-tags-cont tags-list', ->

      span class:'ui-tag-entry', ->
        input type:'text', class:'tag-input input-min', 'data-provide':'typeahead', placeholder:'+ tag'


    isValidTag: (tag)->
      not (tag in @_tags) and (tag.trim() isnt '')

    events: ->
      'keydown input': (e)->
        if e.which in [9,13,188]
          e.preventDefault()
          if @isValidTag((val = $(e.currentTarget).val().trim()))
            @addTag val

        if e.which in [8,46]
          if $(e.currentTarget).val() is ''
            e.preventDefault()
            @removeLastTag()
      'change input': (e)->
        if @isValidTag((val = $(e.currentTarget).val().trim()))
          @addTag $(e.currentTarget).val()

    addTag: (tag)->
      @_tags.push tag
      @renderTags()
      @trigger 'change', @getArray(), @getString()
      @$('input').val('').focus()
      @

    removeLastTag: ->
      removedTag = @_tags.pop()
      @renderTags()
      @trigger 'change', @getArray(), @getString()
      @$('input').val('').focus()
      @


    getArray: ->
      @_tags

    getString: ->
      @_tags.join '|'

    reset: (tags)->
      if _.isString tags then @_tags = (if tags is "" then [] else ((tags.split '|') ? []))
      if _.isArray tags then @_tags = tags ? []

    render: ->
      @$el.html ck.render @template, @
      @$('input').typeahead {
        source: @options.typeahead
      }
      @renderTags()
      @


  class List extends Backbone.View


    initialize: (@options)->
      @state = new UIState {
        term: ''
        selected: []
        page: 0
        show: 30
      }

      @state.on 'change:term', =>
        @renderControls()
        @renderList()

      @state.on 'change:selected', =>
        @renderControls()

      @collection.on 'reset', @render, @

      @collection.on 'add', (i)=>
        @addItem i, true
        @renderControls()


      @collection.on 'remove', (m)=>
        if m.id in @state.get('selected')
          @state.set 'selected', _.without @state.get('selected'), m.id
        @renderControls()

    toggleSelectFiltered: ->
      ui = @state.toJSON()
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

      if sel
        @state.set 'selected', _.union(filtered, selected)
      else
        @state.set 'selected', _.difference(selected, filtered)

      @state.trigger 'change:selected'

    clearSelected: ->
      @state.set 'selected', []

    controlsTemplate: ->


    renderList: ->
      {page,show} = ui = @state.toJSON()
      @state.set 'page', 0
      @$('.list-cont').empty()
      list = _.first @collection.filtered(ui), show
      for item in list
        @addItem item
      @setMoreTrigger()

    renderControls: ->
      @$('.controls-cont').html ck.render @controlsTemplate, @
      @$('button').tooltip {
        placement: 'top'
      }
      @

    renderMore: ->
      {page,show} = @state.toJSON()
      list = _.first _.rest(@collection.filtered(@state.toJSON()), page*show), show
      for file in list
        @addItem file
      @setMoreTrigger()

    setMoreTrigger: ->
      {page,show} = ui = @state.toJSON()
      @$('.show-more-cont').empty()
      if @collection.filtered(ui).length >= (page+1)*show
        showMoreEl = $(ck.render @showMoreTemplate)
        showMoreEl.appendTo @$('.show-more-cont')
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

    showMoreTemplate: ->
      div class:'alert alert-info show-more', "more"



  class IKeyboard extends Backbone.View

    tagName: 'div'
    className: 'ui-ikeyboard'

    keys:
      spa: ['á','é','í','ó','ú','ü','ñ','¿','¡']
      fr: ['à','â','æ','ç','é','è','ë','ê','ï','î','ô','œ','ù','û','ü']
      ita: ['à','è','é','ì','ò','ó','ù']
      ger: ['ä','ö','ü','ß']

    initialize: (@options)->

      _.defaults @options, {
        position: 'bottom'
        language: 'spa'
      }

    events:
      'click .insert-char':'insertChar'

    insertChar: (e)-> 
      console.log $(e.currentTarget)
      insertAtCursor @$cont.find('input')[0], $(e.currentTarget).text()
      clearTimeout @timer
      @$cont.find('input')[0].focus()
      @trigger 'select', $(e.currentTarget).text()

    template: ->
      div class:'btn-toolbar', ->
        div class:'btn-group', ->
          for key in @keys[@options.language]
            button tabindex:'-1', class:'btn btn-mini insert-char', "#{key}"

    render: ->
      @$el.html ck.render @template, @
      @

    show: -> 
      $inp = @$cont.find('input')
      @$el.css {
        position: 'absolute'
        top: "#{$inp.offset().top + $inp.height()}px"
        left: "#{$inp.offset().left}px"
      }
      @$el.show()

    hide: -> 
      @timer = wait 200, =>
        if @isFocused then @hide()
        else @$el.hide()

    open: ($cont)->
      super($cont)
      @$cont = $cont
      @$el.hide()
      $cont.find('input').on 'focus', => @show()
      $cont.find('input').on 'blur', => @hide()
      @$('.insert-char').on 'focus', => @isFocused = true
      @$('.insert-char').on 'blur', => @isFocused = false




  _.extend exports, {
    Slider: Slider
    ConfirmDelete: ConfirmDelete
    IncDec: IncDec
    Alert: Alert
    FlashMessage: FlashMessage
    HtmlEditor: HtmlEditor
    Tags: Tags
    TagsModal: TagsModal
    List: List
    UIState: UIState
    IKeyboard: IKeyboard
    MediaScrubber: MediaScrubber
  }




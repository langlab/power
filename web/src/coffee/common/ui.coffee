module 'UI', (exports,top)->

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
      _.defaults @options, {
        min: 0
        max: 100
        handleWidthPerc: 0   #if 0, width will default to height of the groove
      }

    template: ->
      div class:'slider-groove', -> div class:'slider-handle'

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
      newX = e.offsetX + targetOffsetX
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
        for model in @list
          model.destroy()
        @$el.modal('hide')
        @$el.on 'hidden', => @remove()

    initialize: ->
      if @collection
        @list = @collection.selected()
        @list.modelType = @collection.modelType(true)
      else
        @list = [@model]
        @list.modelType = @model.collection.modelType(false)

    template: ->
      div class:'modal-header', ->
        h3 'Are you sure?'
      div class:'modal-body', ->
        if @length > 1
          p "You are about to delete #{ @length } #{ @modelType }:"
          ul ->
            for model in @
              li "#{model.displayTitle()}"
          if @modelType is 'students'
            p -> 
              text "Don't worry, you'll get back all the "
              span class:'icon-heart'
              text " you've given them."
        else
          p "You are about to delete: #{@[0].displayTitle()}"
          if @modelType is 'students'
            p ->
              text "Don't worry, you'll get back all #{@[0].get 'name'}'s #{@[0].get 'piggyBank'} "
              span class:'icon-heart'

      div class:'modal-footer', ->
        button class:'btn cancel', 'data-dismiss':'modal', "No, don't do it"
        button class:'pull-right btn btn-danger icon-trash icon-large delete', ' DELETE PERMANENTLY'

    render: ->
      @$el.html ck.render @template, @list
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

        div class:'wb-body', ->
          div class:'editor-area', ->

      render: ->
        @$el.html ck.render @template, @options
        @
        





  class Tags extends Backbone.View
    tagName: 'div'
    className: 'tags-ui'

    initialize: (tags)->
      @reset tags

    template: ->
      span class:'tags-cont', ->
        for tag in @_tags
          span class:'label',
      input type:'text', class:'tag-input', placeholder:'add a tag'

    events: ->
      'change input': -> @addtag $(e.target).val()

    addTag: (tag)->
      @_tags.add
      @render() 

    getArray: ->
      @_tags

    getString: ->
      @_tags.join '|'

    reset: (tags)->
      if _.isString tags then @_tags = tags.split '|'
      if _.isArray tags then @_tags = tags

    render: ->
      @$el.html ck.render @tempate @
      @

  [exports.Slider,exports.ConfirmDelete, exports.IncDec, exports.Alert, exports.FlashMessage,exports.HtmlEditor] = [Slider, ConfirmDelete, IncDec, Alert, FlashMessage, HtmlEditor]



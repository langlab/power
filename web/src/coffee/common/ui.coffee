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

    initialize: ->
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
      @setSliderX ((v - @options.min)/(@options.max-@options.min) * @grooveW())
      @

    grooveW: ->
      @groove.width() - @handleW()

    setHandleWidthPerc: (perc)->
      @handle.width (perc*@grooveW()/100) or 8

    setSliderX: (x)->
      # console.log @handleW(), @grooveW(), x
      x = x - (@handleW()/2)
      x = if x < 0 then 0 else if x > @grooveW() then @grooveW() else x
      @$('.slider-handle').css 'left', x

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

  [exports.Slider,exports.ConfirmDelete, exports.IncDec, exports.Alert] = [Slider, ConfirmDelete, IncDec, Alert]

# shared functions and variables

w = window
w.ck = CoffeeKup

# make setTimeout and setInterval less awkward
# by switching the parameters!!

w.wait = (someTime,thenDo) ->
  setTimeout thenDo, someTime
w.doEvery = (someTime,action)->
  setInterval action, someTime

w.logging = true #turn on/off console logging

w.log = (args...)=>
  if w.logging
    console?.log args...


# include the socket connection in every Model and View
Backbone.Model::io = Backbone.Collection::io = Backbone.View::io = window.sock

# override sync to be handled by web socket api
Backbone.Model::sync = Backbone.Collection::sync = (method, model, options, cb)->
  log 'emitting: ','sync', @syncName, method,model,options
  window.app.connection.emit 'sync', @syncName, { method: method, model: model, options: options }, (err, resp)->
    if err then options.error err else options.success resp

Backbone.Model::idAttribute = '_id'

Backbone.Collection::getByIds = (ids)->
  @filter (m)-> m.id in ids

# removes all views from the DOM except for the passed arg
Backbone.Router::clearViews = (exceptFor)->
  if not _.isArray exceptFor then exceptFor = [exceptFor]
  view.close() for key,view of @views when not (key in exceptFor)
  
  $('applet').removeClass('submit-error')

Backbone.View::open = (cont = 'body')->
  @$el.appendTo cont
  @trigger 'open', cont
  @isOpen = true
  @

Backbone.View::close = ->
  @unbind()
  @remove()
  @

Backbone.View::render = ->
  @$el.html ck.render @template, @model ? @collection ? @
  @

Backbone.View::sfx = (name)=>
  @sfx = new Audio()
  @sfx.src = "/mp3/#{name}.mp3"
  @sfx.play()

Backbone.View::tts = (options)=>
  {language,gender,textToSay,rate} = options
  @tts = new Audio()
  @tts.src = "http://tts.langlab.org/#{language}/#{gender}?text=#{textToSay}&rate=#{rate}"
  @tts.play()


Backbone.Router::extendRoutesWith = (xtraRoutes)->
  for name,route of xtraRoutes
    if _.isFunction route
      @route name, name, route
    else
      @route name, route

# to create modules/namespaces

window.module = (target, name, block) ->
  [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
  top    = target
  target = target[item] or= {} for item in name.split '.'
  block target, top


window.LD = (s, t) ->
  n = s.length
  m = t.length
  return m if n is 0
  return n if m is 0

  d       = []
  d[i]    = [] for i in [0..n]
  d[i][0] = i  for i in [0..n]
  d[0][j] = j  for j in [0..m]

  for c1, i in s
    for c2, j in t
      cost = if c1 is c2 then 0 else 1
      d[i+1][j+1] = Math.min d[i][j+1]+1, d[i+1][j]+1, d[i][j] + cost

  d[n][m]



# custom jquery plugins
# used in this app

do ($=jQuery)->

  $.fn.center = ->
    @css "position", "absolute"
    @css "top", Math.max(0, (($(window).height() - @outerHeight()) / 2) + $(window).scrollTop()) + "px"
    @css "left", Math.max(0, (($(window).width() - @outerWidth()) / 2) + $(window).scrollLeft()) + "px"
    @


do ($=jQuery)->

  $.fn.slider = (method)->
    @methods = {

      init: (options={})->
        options.min ?= 0
        options.max ?= 100

        handle = $('<div/>').addClass('slider-handle')
        groove = $('<div/>').addClass('slider-groove')

        root = $(@).addClass('slider-cont') 
        handle.appendTo groove
        groove.appendTo root

        ###
        handle.draggable {
          containment: groove
          axis: 'x'
        }
        ###

        root.on 'mousedown', (e)=>
          @setHandleX e.offsetX
          @data 'dragging', true

        root.on 'mouseover', (e)=>
          @data 'dragging', false

        root.on 'mousemove', (e)=>
          @setHandleX e.offsetX


      setHandleX: (x)=>
        handle.css 'left', x - (handle.width()*0.5)


      update: ->
        log 'move:',newpx = (@data('v')-@options.min)/(@options.max-@options.min)
        $(@).find('.slider-handle').css 'left', newpx
        @

      val: (v)->
        log @data('v'),v
        if v?
          @data('v',v)
          @update
          @
        else @data('v')
    }

    if @methods[method]
      @methods[method].apply this, Array::slice.call(arguments, 1)
    else if typeof method is "object" or not @method
      @methods.init.apply this, arguments
    else
      $.error "Method " + @method + " does not exist"


do ($=jQuery)->
  ###
  # jQuery plugin for a two-click confirm button

  # inner content with class of 'state-initial' shows first
  # content with 'state-confirm' shows to confirm the click
  #
  # if options.initialText and options.confirmText are present,
  # button text is replaced instead
  #
  # triggers 'confirm' event on second click
  #
  # clicking outside the button cancels and takes to initial state
  #
  # call: $(el).confirmBtn({ initialText: ?, confirmState: ? })
  ###

  $.fn.confirmBtn = (options = {})->
    
    init = =>
      @confirmState = false
      if options?.initialText?
        @text options.initialText
      else
        @find('.state-confirm').hide()
        @find('.state-initial').show()

      $('body').off 'click.confirm-btn'

    init()

    @click (e)=>
      e.preventDefault()
      e.stopPropagation()
      if options?.confirmText?
        @text options.confirmText
      else
        @find('.state-initial').toggle()
        @find('.state-confirm').toggle()
      if not (@confirmState = not @confirmState)
        @trigger 'confirm'
        init()
      else
        $('body').on 'click.confirm-btn', init



window.fullscreen = (elem) ->
  domPrefixes = 'Webkit Moz O ms Khtml'.split(' ');

  prefix = undefined
  
  # Mozilla and webkit intialise fullscreen slightly differently
  i = -1
  len = domPrefixes.length

  while ++i < len
    prefix = domPrefixes[i].toLowerCase()
    if elem[prefix + "EnterFullScreen"]
      
      # Webkit uses EnterFullScreen for video
      return prefix + "EnterFullScreen"
      break
    else if elem[prefix + "RequestFullScreen"]
      
      # Mozilla uses RequestFullScreen for all elements and webkit uses it for non video elements
      return prefix + "RequestFullScreen"
      break
  false



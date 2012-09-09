
module 'App.Card', (exports, top)->

  class Model extends Backbone.Model

  class Collection extends Backbone.Collection
    model: Model

  _.extend exports, {
    Model: Model
    Collection: Collection
    Views: Views = {}
  }


module 'App.CardStack', (exports, top)->
  
  class Model extends Backbone.Model
    syncName: 'stack'

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'stack'

  _.extend exports, {
    Model: Model
    Collection: Collection
    Views: Views = {}
  }

  class Views.ListItem extends Backbone.View
    tagName: 'li'
    className: 'cardstack-item'

    template: ->
      span class:'thumbnail', ->
        h3 "#{@model.get('title')}"

    render: ->
      @$el.html ck.render @template, @
      @


  class Views.List extends UI.List

    tagName: 'div'
    className:'cardstack-list'

    template: ->
      div class:'controls-cont', ->
      ul class:'thumbnails cardstack-list-cont', ->

    addItem: (stack)->
      itemView = new Views.ListItem { model: stack }
      itemView.render().open @$('.cardstack-list-cont')
      @

    render: ->
      @$el.html ck.render @template, @
      @renderControls()
      @renderList()

  class Views.Main extends Backbone.View
    tagName: 'div'
    className: 'container buffer-top'

    template: ->
      
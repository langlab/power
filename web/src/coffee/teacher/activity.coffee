
module 'App.Activity', (exports,top)->

  class Model extends Backbone.Model
    syncName: 'activity'
    idAttribute: '_id'

    getTags: ->
      @get('labState').settings.tags.split('|')

    getTitle: ->
      @get('labState').settings.title

    getMediaThumb: ->
      file = new App.File.Model @get('mediaA').file
      file.thumbnail()
      

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'activity'


  [exports.Model, exports.Collection] = [Model,Collection]

  exports.Views = Views = {}

  class Views.ModalSelect extends Backbone.View
    tagName: 'div'
    className: 'modal fade hide'

    initialize: (@options)->

      @on 'open', =>
        
        @$el.modal 'show'

        @$el.on 'shown', =>
          @delegateEvents()

        @$el.on 'hidden', =>
          @remove()

    events:
      'click .create-activity':'createActivity'
      'click .activity': (e)->
        @trigger 'select', @collection.get($(e.currentTarget).attr('data-id'))
        @close()


    createActivity: ->
      newAct = @collection.create {
        labState: {
          settings: {
            title: 'Untitled'
            tags: ''
          }
        }
      }
      @trigger 'select', newAct
      @close()

    listTemplate:->


    template: ->
      div class:'modal-header', ->
        h3 'Lab activities'
      div class:'modal-body', ->

        if @collection.models.length is 0
          p "You don't have any activities yet."
        else
          table class:'table table-condensed table-hover', ->
            tbody class:'activity-list', ->
              for activity in @collection.models
                tr class:'activity', 'data-id':"#{activity.id}", -> 
                  td ->
                    div "#{activity.getTitle()}"
                  td ->
                    for tag in activity.getTags()
                      span class:'tag', "#{tag}"

      
      div class:'modal-footer', ->
        button class:'btn btn-success icon-plus create-activity', " Create a new activity"


    render: ->
      @$el.html ck.render @template, @
      @$el.modal { backdrop: 'static' }
      @

    close: ->
      @$el.modal 'hide'

  class Views.Settings extends Backbone.View
    

module 'App.Lab', (exports, top)->

  class UIState extends Backbone.Model

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: ->  

      @set {
        'whiteBoardA': new UIState { html: 'yoyoyo' }
        'whiteBoardB': new UIState
      }

    fromDB: (data)->
      console.log 'fromDB: ',data
      {method,model,options} = data

      switch method

        when 'action'

          {action} = model

          switch model.action
            
            when 'update'
              console.log 'update'
              for prop,val of model when prop isnt 'action'
                @get(prop)?.set val




  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'




  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.WhiteBoard extends Backbone.View
    tagName:'div'
    className: 'wb-cont'

    initialize: ->

      @model.on 'change:html', =>
        console.log 'changing html',@model.get 'html'
        @render()



    render: ->
      @$el.html @model.get('html')
      @


  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->

      @wbA = new Views.WhiteBoard { model: @model.get 'whiteBoardA' }
      @wbB = new Views.WhiteBoard { model: @model.get 'whiteBoardB' }

    template: ->
      div class:'row-fluid', ->

        div class:'span6', ->
          div class:'media-cont-a media-cont', ->
            file = @get('mediaA')?.file
            console.log file
            if file?
              switch file.type
                when 'image'
                  img src:"#{file.imageUrl}"
                when 'video'
                  video ->
                    source src:"#{file.webmUrl}"
                    source src:"#{file.h264Url}"
                when 'audio'
                  audio ->
                    source src:"#{file.mp3Url}"

          div class:'media-cont-b media-cont', ->
            file = @get('mediaB')?.file
            if file?
              switch file.type
                when 'image'
                  img src:"#{file.imageUrl}"
                when 'video'
                  video ->
                    source src:"#{file.webmUrl}"
                    source src:"#{file.h264Url}"
                when 'audio'
                  audio ->
                    source src:"#{file.mp3Url}"


        div class:'span6', ->

          div class:'wb-cont-a', ->

          div class:'wb-cont-b', ->


    render: ->
      super()
      @wbA.render().open @$('.wb-cont-a')
      @wbB.render().open @$('.wb-cont-b')
      @






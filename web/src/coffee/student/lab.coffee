module 'App.Lab', (exports, top)->

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    initialize: ->  

    fromDB: (data)->
      console.log 'fromDB: ',data
      {method,model,options} = data

      switch method

        when 'update:state'
          console.log 'update:state recvd:',data
          @set model



  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'




  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->

      @model.on 'change', =>
        @render()


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


        div class:'span6', ->

          div class:'wb-cont-a wb-cont', ->
            "#{@get 'whiteBoardA'}"

          div class:'wb-cont-b wb-cont', ->
            "#{@get 'whiteBoardB'}"






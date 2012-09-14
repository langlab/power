
module 'App.Response', (exports,top)->
  
  class Model extends Backbone.Model
    syncName: 'response'

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'response'

    fromDB: (data)->
      {method, model, options} = data
      console.log 'updating ',model
      switch method
        when 'create'
          @add model

    forStudent: (studentId)->
      @filter (m)-> m.get('student') is studentId

  _.extend exports, {
    Model: Model
    Collection: Collection
    Views: Views = {}
  }

  class Views.List extends Backbone.View

    tagName: 'table'
    className: 'table table-condensed'

    template: ->



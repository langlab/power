
module 'App.Question.ShortAnswer', (exports,top)->
  
  class Model extends Backbone.Model

  class Collection extends Backbone.Collection
    model: Model

  _.extend exports, {
    Model: Model
    Collection: Collection
    Views: Views = {}
  }

  


module 'App.Response', (exports,top)->
  
  class Model extends Backbone.Model
    syncName: 'response'

  class Collection extends Backbone.Collection
    model: Model

  _.extend exports, {
    Model: Model
    Collection: Collection
  }

module 'App.Activity', (exports,top)->

  class Model extends Backbone.Model
    syncName: 'activity'
    idAttribute: '_id'

  class Collection extends Backbone.Collection
    model: Model
    syncName: 'activity'



  [exports.Model, exports.Collection] = [Model,Collection]

  exports.Views = Views = {}
module 'App.Lab', (exports, top)->

  class Model extends Backbone.Model
    syncName: 'lab'
    idAttribute: '_id'

    defaults:
      message: 'hello!'

    initialize: (options)->

      _.extend @, options

      @attributes.teacherId = @teacher.id
      @set @teacher.get('labState')

      @on 'change', @updateState, @


    addStudent: (studentId)->
      @sync 'add:student', null, {
        studentIds: [studentId]
        success: (data)=>
          console.log 'student added: ',data
      }

    removeStudent: (studentId)->
      @sync 'remove:student', null, {
        studentIds: [studentId]
        success: (data)=>
          console.log 'student removed', data
      }

    getStudents: ->
      @sync 'read:students', null, {
        success: (data)=>
          console.log 'students: ',data
      }

    updateState: ->
      console.log 'updating state...'
      @sync 'update:state', @toJSON(), {
        success: (err,data)=>
          console.log 'state updated: ',data
      }


  class Collection extends Backbone.Collection
    model: Model
    syncName: 'lab'


  [exports.Model, exports.Collection] = [Model, Collection]

  exports.Views = Views = {}

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->
      @wb = new UI.HtmlEditor
      
      @on 'open', =>
        @wb.open @$('.wb-cont')
        @delegateEvents()

    events:
      'keyup .editor-area':'saveWhiteBoard'
      'click .toggle-control': (e)->
        @model.students.get($(e.currentTarget).attr('data-id')).toggleControl()

    saveWhiteBoard: (e)->
      console.log e
      @model.set 'whiteboard', @wb.simplifiedHTML()


    template: ->
      #div class:'container-fluid', ->
      div class:'row-fluid', ->
        div class:'span2 sidebar', ->
          div class:'accordion-group', ->
            div class:'collapse-head accordion-heading accordion-toggle', ->
              div 'data-toggle':'collapse', 'data-target':'.lab-students', 'Students'
            div class:'collapse in lab-students accordion-body collapse in', ->
              div class:'accordion-inner', ->
                table class:'table', ->
                  for stu in @students.models
                    tr ->
                      td -> button 'data-id':"#{stu.id}", class:"btn icon-hand-up box toggle-control #{if stu.get('control') then 'active' else ''}", 'data-toggle':'button'
                      td "#{stu.get 'name'}"
          div class:'accordion-group', ->
            div class:'collapse-head accordion-heading accordion-toggle', ->
              div 'data-toggle':'collapse', 'data-target':'.lab-files', 'Files'
            div class:'collapse in lab-files accordion-body collapse in', ->
              div class:'accordion-inner', ->
                table class:'table', ->
                  for file in @filez.models
                    tr ->
                      td -> img src:"#{file.thumbnail()}"
                      td "#{file.get 'title'}"
        
        div class:'span5', ->
          video src:'',width:'100%',controls:true
        div class:'span5 content', ->
          div class:'wb-cont', ->

    render: ->
      super()
      @wb.render()
      @




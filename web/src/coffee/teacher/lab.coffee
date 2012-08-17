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

  class Views.LabStudent extends Backbone.View
    tagName: 'tr'
    className: 'lab-student'

    initialize: ->
      @model.on 'change:online', (online)=>
        @$('.icon-heart').toggleClass 'online', online

    template: ->
      td -> button 'data-id':"#{@id}", class:"btn icon-hand-up box toggle-control #{if @get('control') then 'active' else ''}", 'data-toggle':'button'
      td -> i class:"online-status icon-heart #{if @get 'online' then 'online' else ''}"
      td "#{@get 'name'}"

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'lab-view container'

    initialize: ->
      @wbA = new UI.HtmlEditor { html: @model.get 'whiteBoardA' }
      @wbB = new UI.HtmlEditor { html: @model.get 'whiteBoardB' }
      @on 'open', =>
        @wbA.open @$('.wb-a-cont')
        @wbB.open @$('.wb-b-cont')
        @$('video').attr('src',@model.filez.at(2).get('webmUrl'))
        @delegateEvents()


    events:
      'keyup .wb-a-cont .editor-area':'saveWhiteBoardA'
      'keyup .wb-b-cont .editor-area':'saveWhiteBoardB'
      'click .wb-a-cont':'saveWhiteBoardA'
      'click .wb-b-cont':'saveWhiteBoardB'

      'click .toggle-control': (e)->
        @model.students.get($(e.currentTarget).attr('data-id')).toggleControl()

    saveWhiteBoardA: (e)->
      console.log e
      @model.set 'whiteBoardA', @wbA.simplifiedHTML()

    saveWhiteBoardB: (e)->
      console.log e
      @model.set 'whiteBoardB', @wbB.simplifiedHTML()


    template: ->
      #div class:'container-fluid', ->
      div class:'row-fluid', ->
        div class:'accordion-group span12', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-timeline', 'Timeline'
            div class:'lab-timeline accordion-body collapse', ->
              div class:'accordion-inner', ->
                text "put the timeline in here!"
      
      div class:'row-fluid', ->
        div class:'span2 sidebar', ->

          div class:'accordion-group', ->
            div class:'accordion-heading ', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-students', 'Students'
            div class:'collapse in lab-students accordion-body', ->
              div class:'accordion-inner', ->
                table class:'table lab-student-list', ->
                  
                      
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-files', 'Files'
            div class:'collapse in lab-files accordion-body', ->
              div class:'accordion-inner', ->
                table class:'table', ->
                  for file in @filez.models
                    tr ->
                      td -> img src:"#{file.thumbnail()}"
                      td "#{file.get 'title'}"
        
        div class:'span5', ->
          video src:'',width:'100%',controls:true

        div class:'span5 content', ->
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-wb-a', 'Whiteboard A'
            div class:'collapse in lab-wb-a accordion-body', ->
              div class:'accordion-inner', ->
                div class:'wb-a-cont', ->
          div class:'accordion-group', ->
            div class:'accordion-heading', ->
              a class:'accordion-toggle', 'data-toggle':'collapse', 'data-target':'.lab-wb-b', 'Whiteboard B'
            div class:'collapse lab-wb-b accordion-body', ->
              div class:'accordion-inner', ->
                div class:'wb-b-cont', ->

    render: ->
      super()
      for stu in @model.students.models
        sv = new Views.LabStudent { model: stu }
        sv.render().open @$('.lab-student-list')
      @wbA.render()
      @wbB.render()

      @




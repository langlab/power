
module 'App.Student', (exports,top)->

  exports.Views = Views = {}

# the main student model 
  class Model extends Backbone.Model
    syncName: 'student'
    idAttribute: '_id'

    modelType: (plural=false)->
      "student#{ if plural then 's' else ''}"

    displayTitle: ->
      "#{@get 'firstName'} #{@get 'lastName'} (#{@get 'email'})"

    initialize: ->
      
    isSelected: ->
      @get 'selected'

    toggleSelect: ->
      @set 'selected', not @get('selected')

    validate: (attrs)->
      {password} = attrs
      errObj =
        errors: {}
      if attrs.password? and not password.match /[^ ]{6,}/
        errObj.errors.password = "password must be at least 6 characters, no spaces"

      if not _.isEmpty errObj.errors
        return errObj


    randomPassword: ->

    passwordMask: ->
      pw = @get 'password'
      pw.replace /./g,'*'

    match: (query)->
      re = new RegExp query,'i'
      #console.log 'querying...',query, @
      (re.test @get('firstName')) or (re.test @get('lastName')) or (re.test @get('email'))

# collection of students
  class Collection extends Backbone.Collection
    model: Model
    syncName: 'student'

    modelType: ->
      "students"

    initialize: ->
      @io.on 'connect', =>
        @fetch()

    selected: ->
      @filter (s)-> s.isSelected()

    filtered: ->
       @filter (m)=> m.match(@searchTerm ? '')

    selectedFiltered: ->
      _.filter @filtered(), (m)-> m.get('selected') is true

    selectFiltered: (setTo = true)->
      for student in @filtered()
        student.set 'selected', setTo

    toggleSelectFiltered: ->
      if @selectedFiltered().length is @filtered().length
        @selectFiltered false
      else if @selectedFiltered().length is 0
        @selectFiltered true
      else
        @selectFiltered false



# model for the main view's UI state
  class UIState extends Backbone.Model
    defaults:
      currentListView: 'list'
      searchTerm: ''
      addMode: false

    toggleAddMode: ->
      @set 'addMode', (@get 'addMode')
      @


  



# for the special show/hide password field
  class Views.Password extends Backbone.View
    tagName: 'input'
    className: 'password'

    initialize: ->
      @_val = @el.value
      @updateInput()
          
    mask: ->
      @_val.replace /./g, '*'

    events:
      'focus': ->
        @focus = true
        @updateInput()

      'mouseover':->
        @mouseover = true
        @updateInput()

      'mouseout':->
        @mouseover = false
        @_val = @$el.val()
        @updateInput()
        

      'click': ->
        @focus = true
        @updateInput

      'blur': ->
        @focus = false
        @updateInput()

      'keyup': ->
        @_val = @el.value

    updateInput: ->
      @el.value = (if @focus or @mouseover then @_val else @mask())
      @

    val: (v)->
      if v
        @_val = v
        @updateInput()
        @
      else @_val


# the main view, including search bar
  class Views.Main extends Backbone.View
    tagName: 'div'
    className: 'student-main-view'

    initialize: ->
      @listView = new Views.List { collection: @collection }

      @ui = new UIState()

      @ui.on 'change:searchTerm', =>
        @collection.searchTerm = @$('.search-query').val()
        @updateBar()
        @renderList()
        @listView.toggleNew @ui.get 'addMode'

      @ui.on 'change:addMode', (v)=>
        @listView.toggleNew @ui.get 'addMode'

      @collection.on 'reset', =>
        @render()

      @collection.on 'change:selected', (m)=>
        @updateBar()
       

    events:
      'keyup input.search-query': 'search'
      'click .add-students': (e)-> @ui.toggleAddMode()
      'click .toggle-select-all': -> @collection.toggleSelectFiltered()
      'click .delete-students': 'deleteStudents'

    search: (e)->
      clearTimeout @searchWait
      @searchWait = wait 200, => @ui.set 'searchTerm', $(e.target).val()

    deleteStudents: ->
      deleteConfirm = new UI.ConfirmDelete { collection: @collection.selected() }
      deleteConfirm.render().open()

    buttonGroupTemplate: ->
      if (numSel = @collection.selected().length)
        button rel:'tooltip', class:'btn btn-danger icon-trash delete-students', 'title':'delete these files', ' Delete'

      button rel:'tooltip', title:'add students', class:"btn btn-success icon-plus add-students #{ if @ui.get 'addMode' then 'active' else ''}", 'data-toggle':'button', ->
        i class:'icon-group'
        span ' Add'


    checkAllTemplate: ->
      if @collection.selectedFiltered().length is @collection.filtered().length then checkClass = 'check icon-large'
      else if @collection.selectedFiltered().length is 0 then checkClass = 'check-empty icon-large'
      else checkClass = 'reorder'
      div class:"icon-#{checkClass} pull-left toggle-select-all", ' '

    template: ->
      div class:'search-panel', ->
        input class:'search-query', type:'text', placeholder:'search', value:"#{@ui.get 'searchTerm'}"

      div class:'list-panel', ->
        div class:'files-top-bar', ->
          
          span class:'btn-toolbar', ->
            
            span class:'check-all-cont', ->
            
            #h3 class:'pull-left', "#{ @collection.filtered?.length ? @collection.length } students shown, #{ @collection.selected().length } selected, of #{ @collection.length } total"

            
            div class:'btn-group pull-right', ->
              
        # where the list goes
        div class:'student-list-cont', ->

    updateBar: ->
      @$('.check-all-cont').html ck.render @checkAllTemplate, @
      @$('.btn-group').html ck.render @buttonGroupTemplate, @

    
    renderList: ->
      @listView.render().open @$('.student-list-cont')
      @

    render: ->
      @$el.html ck.render @template, @
      @updateBar()
      @renderList()
      @$('button').tooltip { placement: 'bottom' }
      @delegateEvents()
      @


# the entire list view of students
  class Views.List extends Backbone.View
    tagName: 'table'
    className: 'table student-list'

    initialize: ->

      @collection.on 'reset', =>
        @render()

      @collection.on 'add', (item)=>
        @addItem item, true

      @newItem = new Model()

      @newItem.on 'saved', =>
        newItem = @collection.add @newItem.clone()

    events:
      'keydown thead.new-student input.password': (e)-> if e.which in [9,13] then @newItemView.saveNew()

    template: ->

      # row for new students go here
      thead class:'off new-student', ->

      # where the student list items go
      tbody ->

    addItem: (item, prepend = false)=>
      iv = new Views.ListItem model: item 
      $cont = @$("#{ if item.isNew() then 'thead' else 'tbody'}")
      $viewEl = iv.render().$el
      if prepend then $viewEl.prependTo $cont 
      else $viewEl.appendTo $cont

      if item.isNew()
        @newItemView = iv 
        iv.$('input:first').focus()

    toggleNew: (turnOff)=> 
      @$('thead.new-student').toggleClass 'off', turnOff
      if turnOff then @$('thead.new-student input:first').focus()

    renderList: ->
      for item in @collection.filtered()
        @addItem item
      @

    render: =>
      @$el.html ck.render @template
      @renderList()
      @addItem @newItem
      @delegateEvents()
      @

# each student row in the list
  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'student-list-item list-item'

    initialize: ->

      @model.on 'change', =>
        @$('input').removeClass('err')

      @model.on 'change:selected', =>
        @model.collection.trigger 'change:selected', @model
        @render()

      @model.on 'remove', =>
        @remove()

      @model.on 'error', @showErrors

      @model.on 'reset', @render()

    template: ->
      td ->
        if @isNew()
          i class:"icon-caret-right icon-large"
        else
          i class:"icon-check#{ if not @isSelected() then '-empty' else '' } select-student"
      td ->
        i class:'icon-user icon-large'
      td -> 
        #div class:'control-group lastName'
        input 'data-field':'lastName', value:"#{@get('lastName') ? ''}", placeholder:'Last Name'
      td -> 
        input 'data-field':'firstName', value:"#{@get('firstName') ? ''}", placeholder:'First Name'
      td ->
        input 'data-field':'email', value:"#{@get('email') ? ''}", placeholder:'email'
      td ->
        input 'data-field':'password', class:'password', placeholder: 'Password', value:"#{@get('password') ? ''}"
      if @isNew()
        td ->
          i class:'icon-plus add'
      else
        td ->
          i class:'icon-trash delete'

    passwordMask: ->
      pw = @$('.password').val()
      pw.replace /./g,'*'

    events:
      'change input': 'saveField'
      'click .delete':'deleteItem'
      'click .add':'saveNew'
      'click .select-student': -> @model.toggleSelect()

    saveField: (e)=>
      if not @model.isNew()
        field = $(e.target).attr 'data-field'
        (attrs = {})[field] = if field is 'password' then @passwordEl.val() else $(e.target).val()

        @model.save attrs, {
          error: @showErrors
          success: @clearErrors
        }

    saveNew: =>
      attrs = {}
      for fld in @$('[data-field]')
        attrs[field = $(fld).attr('data-field')] = if field is 'password' then @passwordEl.val() else $(fld).val()

      @model.save attrs, {
        error: @showErrors
        success: => 
          @model.trigger 'saved'
          @model.clear()
          @render().$('input:first').focus()
      }

    deleteItem: ->
      @deleteConfirm = new UI.ConfirmDelete { collection: [ @model ] }
      @deleteConfirm.render().open()
      #@model.destroy()


    showErrors: (model,errObj)=>
      @$('.model-status').removeClass('icon-ok').addClass('icon-warning-sign')
      for fieldName,err of errObj.errors
        fieldEl = @$("input[data-field='#{fieldName}']")
        fieldEl.addClass('err').attr 'title', err
        fieldEl.focus()

    render: ->
      super()
      @passwordEl = new Views.Password { el: @$('.password') }
      @$el.toggleClass 'selected', @model.isSelected()
      @



  [exports.Model,exports.Collection,exports.UIState] = [Model,Collection,UIState]




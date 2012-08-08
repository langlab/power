
module 'App.Student', (exports,top)->

  exports.Views = Views = {}

# the main student model 
  class Model extends Backbone.Model
    syncName: 'student'
    idAttribute: '_id'

    modelType: (plural=false)->
      "student#{ if plural then 's' else ''}"


    displayTitle: ->
      "#{@get 'name'} (#{@get 'email'})"


    initialize: ->
      
    isSelected: ->
      @get 'selected'

    toggleSelect: ->
      @set 'selected', not @get('selected')


    randomPassword: ->

    passwordMask: ->
      pw = @get 'password'
      pw.replace /./g,'*'

    match: (query)->
      re = new RegExp query,'i'
      #console.log 'querying...',query, @
      (re.test @get('name')) or (re.test @get('email'))

# collection of students
  class Collection extends Backbone.Collection
    model: Model
    syncName: 'student'

    modelType: ->
      "students"

    initialize: ->

    selected: ->
      @filter (s)-> s.isSelected()

    selectionState: ->
      if @selectedFiltered().length is @filtered().length then selState = 'all'
      else if @selectedFiltered().length is 0 then selState = 'none'
      else selState = 'some'
      selState

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


  class UIState extends Backbone.Model

    defaults:
      currentListView: 'list'
      searchTerm: ''
      addMode: false

    toggleAddMode: ->
      @set 'addMode', (@get 'addMode')
      @

  class Views.Main extends Backbone.View

    tagName: 'div'
    className: 'student-main container'

    initialize: ->
      @state = new UIState

      @collection.on 'reset', @render, @

      @collection.on 'add', (i)=>
        @addItem i, true
        @renderControls()

      @collection.on 'remove', =>
        @renderControls()

      @collection.on 'saved', =>
        fm = new App.Teacher.Views.FlashMessage { message: 'changes saved', type: 'success' , time: 1000 }
        fm.render()

      @state.on 'change:adding', (m,v)=>
        @quickAdd()

      @state.on 'change:searchTerm', =>
        @collection.searchTerm = @$('input.search').val()
        @renderControls()
        @renderList()

      @newItem = new Views.NewListItem { collection: @collection }

    events:
      'click .add-students': -> 
        @state.set 'adding', (not @state.get 'adding')

      'click .delete-students': ->
        dc = new UI.ConfirmDelete { collection: @collection.selected() }
        dc.render().open()

      'click .email-students': ->
        es = new Views.EmailStudents { collection: @collection.selected() }
        es.render().open()

      'click .toggle-select-all': ->
        @collection.toggleSelectFiltered()

      'keyup input.search': 'search'


    selectIcons:
      'all':'check'
      'none':'check-empty'
      'some':'reorder'

    selectStrings:
      'all':'Unselect all'
      'none':'Select all'
      'some':'Unselect all'

    search: (e)->
      clearTimeout @searchWait
      @searchWait = wait 200, => @state.set 'searchTerm', $(e.target).val()

    quickAdd: ->
      if @state.get 'adding'
        @newItem.render().open @$('.new-item-cont')
        @newItem.focus()
        @newItem.delegateEvents()
      else
        @newItem.remove()

    controlsTemplate: ->
      div class:'btn-toolbar span12', ->
        div class:'btn-group pull-left', ->
          button class:"btn pull-left icon-#{@selectIcons[selState = @collection.selectionState()]} toggle-select-all", " #{@selectStrings[selState]}"
        
        div class:'btn-group pull-right', ->
          button class:'btn btn-success icon-plus add-students', 'data-toggle':'button', ' Quick add'
        if @collection.selected().length
          div class:'btn-group pull-right', ->
            button class:'btn btn-info icon-envelope email-students', " Send Email (#{@collection.selected().length})"
            button class:'btn btn-danger icon-trash delete-students', " Delete (#{@collection.selected().length})"
        

    template: ->
      div class:'row', ->
        div class:'btn-group input-prepend pull-left span6', ->
          span class:'add-on icon-search'
          input type:'text', class:'search', placeholder:"search #{@collection.modelType()}"

        
      div class:'controls-cont row', ->
        
      table class:'list-cont table', ->
        thead class:'new-item-cont'
        tbody class:'list', ->
                

    addItem: (stu,prepend=false)->
      v = new Views.ListItem { model: stu, collection: @collection }
      v.render()
      if prepend
        v.$el.prependTo @$('.list')
      else
        v.$el.appendTo @$('.list')

      stu.on 'change:selected', @renderControls, @


    renderControls: ->
      @$('.controls-cont').html ck.render @controlsTemplate, @
      @

    renderList: ->
      @$('.list').empty()
      for stu in @collection.filtered() ? @collection.models
        @addItem stu
      @quickAdd()

    render: ->
      @$el.html ck.render @template, @
      @$('.message').alert('close')
      @renderList()
      @renderControls()
      @delegateEvents()
      @

  class Views.NewListItem extends Backbone.View
    tagName: 'tr'
    className: 'list-item'

    initialize: ->

    events:
      'click .add-item': 'addItem'
      'keydown .email': (e)->
        if e.which in [9,13] and not e.shiftKey
          @addItem()


    focus: ->
      @$('input:first').focus()

    addItem: ->
      @collection.create {
        name: @$('.name').val()
        email: @$('.email').val()
      }, {
        error: (m,e)=>
          console.log 'error: ',m,e
        success: =>
          @clear().focus()
      }

    clear: ->
      @$('.name').val ''
      @$('.email').val ''
      @

    template: ->
      td ->
        i class:'icon-caret-right'
      td ->
        i class:'icon-user'
      td ->
        div class:'control-group', ->
          input type:'text', placeholder:'name', class:'name'
          span class:'help-block'
      td ->
        div class:'control-group', ->
          input type:'text', placeholder:'email', class:'email'
          span class:'help-block'
      td ->
        i class:'icon-plus add-item'


  class Views.ListItem extends Backbone.View

    tagName: 'tr'
    className: 'list-item'

    initialize: ->
      @model.on 'change', @render, @

      @model.on 'remove', @remove, @

    events:
      'click .select-item': -> @model.toggleSelect()

      'click .delete-item': ->
        dc = new UI.ConfirmDelete { collection: [@model] }
        dc.render().open()

      'click .manage-password': ->
        managePassword = new Views.ManagePassword model:@model
        managePassword.render().open()

      'change input': ->
        @model.save { name: @$('input.name').val(), email: @$('input.email').val() }, {
          error: => @showErrors()
          success: => @clearErrors()
        }

    showErrors: (model,errObj)=>
      for fieldName,err of errObj.errors
        fieldEl = @$("input.#{fieldName}")
        fieldEl.addClass('err')
        @$(".control-group.#{fieldName} .help-block").text "#{err.type}"
        fieldEl.focus()

    clearErrors: (x,y)->
      @$('.control-group .help-block').text ''
      @collection.trigger 'saved'

    template: ->
      td  ->
        i class:"#{ if @isSelected() then 'icon-check' else 'icon-check-empty' } icon-large select-item"
      td ->
        #img src:'http://placehold.it/75x100'
        i class:'icon-user'
      td -> 
        div class:'control-group name', ->
          input type:'text', value:"#{ @get 'name' }", placeholder:'name', class:'name'
          span class:'help-block name'
      td ->
        div class:'control-group email', ->
          input type:'text', value:"#{ @get 'email' }", placeholder:'email', class:'email'
          span class:'help-block email'
      td ->
        div class:'manage-password', ->
          i class:'icon-key'
        div class:'delete-item', ->
          i class:'icon-trash'

    render: ->
      super()
      if @model.isSelected() then @$el.addClass 'selected' else @$el.removeClass 'selected'
      @$('input').tooltip()
      @

  class Views.ManagePassword extends Backbone.View
    tagName:'div'
    className:'modal manage-password-view hide fade'

    initialize: ->
      @$el.modal()

      @model.on 'change:password', @render, @

    
    chargeEmailButton: ->
      @$('.send-pw').one 'click', (e)=>
        console.log 'clicked'
        $(e.target).off().addClass('disabled').text(' Sending...')
        @model.sync 'email', { _id: @model.id }, {
          subject: 'your password'
          body: "your password is #{@model.get 'password'}" 
          error: (model,err)-> console.log model, err
          success: =>
            $(e.target)
              .removeClass('icon-envelope')
              .addClass('icon-ok')
              .removeClass('btn-info')
              .addClass('btn-success')
              .addClass('disabled')
              .text ' Email sent!'
        }

    events:
      'click .generate-pw': ->
        @model.save { password: '*' }, { regenerate: true }        

    template: ->
      div class:'modal-body', ->
        span class:'icon-key pw', " #{@get 'password'}"
        span "  is #{@get 'name'}'s password."
      div class:'modal-footer', ->
        div class:'btn-toolbar', ->
          div class:'btn-group', -> button class:'btn btn-info icon-envelope send-pw', " Email password to #{@get 'name'}"
          div class:'btn-group', -> button class:'btn btn-warning icon-refresh generate-pw', " Generate a new one"
          div class:'btn-group', -> button class:'btn', 'data-dismiss':'modal', "Close"

    render: ->
      @$el.html ck.render @template, @model
      @chargeEmailButton()
      @


  class Views.EmailStudents extends Backbone.View
    tagName: 'div'
    className: 'modal hide fade'

    initialize: ->
      @$el.modal()

    template: ->
      div class:'modal-header', ->
        h2 'Email students'
      div class:'modal-body', ->




  class Views.Detail extends Backbone.View

    tagName:'div'
    className:'detail'

    initialize: ->

    showErrors: (model,errs)->
      console.log errs
      for type,err of errs.errors
        @$(".control-group.#{type}").addClass('error')
        @$(".control-group.#{type} .help-block").text err.type


    events:
      'keyup .name': -> @$('.full-name').text(" #{ @$('input.firstName').val() ? '' } #{ @$('input.lastName').val() ? '' }")
      'click .save': ->
        model = {}
        for fld in @$('.fld')
          model[$(fld).attr('data-fld')] = $(fld).val()

        @model.save model, {
          error: (model,errs) => @showErrors(model, errs)
          success: -> top.app.router.navigate 'students', true
        }
            
    
    template: ->
      div class:'page-header', ->
        h2 class:'icon-user icon-large full-name', " #{ @get('name') ? '' }"
      fieldset ->
        div class:'control-group name', ->
          input type:'text', class:'fld firstName name', 'data-fld':'name', placeholder:'Name', value:"#{ @get('name') ? '' }"
          span class:'help-block'
        div class:'control-group email', ->
          div class:'input-prepend', ->
            span class:'add-on', -> 
              i class:'icon-envelope'
            input type:'text', class:'fld email', 'data-fld':'email', placeholder:'email', value: "#{ @get('email') ? '' }"
          span class:'help-block'
        div class:'control-group password', ->
          
          div class:'input-prepend', ->
            span class:'add-on', -> i class:'icon-key'
            input type:'text', class:'fld password', 'data-fld':'password', value: "#{ @get('password') ? '' }"
            span -> 
              a href:'#', rel:'popover', class:'password-toggle', 'data-content':"is #{ @get('firstName') ? '' }'s password", 'data-title':"#{@get('password') ? ''}", 'data-placement':'left', ->
              i class:'icon-eye'
          
          span class:'help-block'

      div class:'page-header'
      button class:'save btn btn-success icon-check', ' Save changes'


  [exports.Model,exports.Collection,exports.UIState] = [Model,Collection,UIState]

###
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


  

###


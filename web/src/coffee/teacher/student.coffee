
module 'App.Student', (exports,top)->

  exports.Views = Views = {}

# the main student model 
  class Model extends Backbone.Model
    syncName: 'student'
    idAttribute: '_id'

    initialize: -> 
      
    getLoginKey: (cb)->
      @sync 'getLoginKey', @toJSON(), {
        error: cb
        success: cb
      }

    modelType: (plural=false)->
      "student#{ if plural then 's' else ''}"


    displayTitle: ->
      "#{@get 'name'} (#{@get 'email'})"

      
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
      (re.test @get('name')) or (re.test @get('email')) or (re.test @get('tags'))

    changePennies: (byAmount,cb)->
      @sync 'changePennies', @toJSON(), {
        byAmount: byAmount
        error: (m,err)=> console.log err
        success: (m,resp)=>
          console.log 'success', m,resp
          @set 'piggyBank', m.piggyBank
      }

    toggleControl: ->
      @sync 'changeControl', null, {
        ids: [@id]
        control: not @get('control')
        success: =>
      }

# collection of students
  class Collection extends Backbone.Collection
    model: Model
    syncName: 'student'
    _selected: []

    fromDB: (data)->
      console.log 'fromDB: ',data
      {method,model,options} = data

      switch method
        when 'online'
          @get(model._id).set 'online', model.online

        when 'control'
          @get(model._id).set 'control', model.control

        when 'help'
          @get(model._id).set 'help', model.help


    allTags: ->
      _.union _.flatten @map (m)-> m.get('tags')?.split('|') ? []

    modelType: ->
      "students"

    studentsNeedingHelp: ->
      (@filter (s)-> s.get('help')).length

    initialize: ->
      @on 'reset', =>
        if @_selected then @get(id).toggleSelect() for id in @_selected

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

    controlled: ->
      @filter (m)=> m.get('control')

    notControlled: ->
      @filter (m)=> not m.get('control')

    selectedControlled: ->
      _.filter @selected(), (m)-> m.get('control') is true

    toggleSelectFiltered: ->
      if @selectedFiltered().length is @filtered().length
        @selectFiltered false
      else if @selectedFiltered().length is 0
        @selectFiltered true
      else
        @selectFiltered false

    toggleControl: ->
      @sync 'changeControl', null, {
        ids: _.pluck(@selected(),'id')
        control: (@selectedControlled().length isnt @selected().length)
        success: =>
      }




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
      @searchBox = new top.App.Teacher.Views.SearchBox


      @collection.on 'reset', @render, @

      @collection.on 'add', (i)=>
        @addItem i, true
        @renderControls()

      @collection.on 'remove', =>
        @renderControls()

      @collection.on 'saved', =>
        fm = new UI.FlashMessage { message: 'changes saved', type: 'success' , time: 1000, cont: @$('.message-cont') }
        fm.render()

      @state.on 'change:adding', (m,v)=>
        @quickAdd()

      @searchBox.on 'change', (v)=>
        @collection.searchTerm = v
        @renderControls()
        @renderList()

      @newItem = new Views.NewListItem { collection: @collection }

    events:
      'click .add-students': -> 
        @state.set 'adding', (not @state.get 'adding')

      'click .delete-students': ->
        dc = new UI.ConfirmDelete { collection: @collection }
        dc.render().open()

      'click .email-students': ->
        es = new Views.EmailStudents { collection: @collection }
        es.render().open()

      'click .passwords': ->
        pws = new Views.Passwords { collection: @collection }
        pws.render()

      'click .toggle-select-all': ->
        @collection.toggleSelectFiltered()

      'click .control-students': ->
        @collection.toggleControl()

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
        div class:'btn-group pull-left message-cont', ->
          button class:"btn btn-mini pull-left icon-#{@selectIcons[selState = @collection.selectionState()]} toggle-select-all", " #{@selectStrings[selState]}"
        
        div class:'btn-group pull-right', ->
          button class:"btn btn-mini btn-success icon-plus add-students #{ if @state.get('adding') then 'active' else ''}", 'data-toggle':'button', ' Quick add'
        if @collection.selected().length

          div class:'btn-group pull-left', ->
            button class:'btn btn-mini btn-info icon-envelope email-students', ' Email'
            button class:'btn btn-mini btn-warning icon-key passwords', ' Passwords'
            button class:'btn btn-mini icon-heart heartbeats', ' Heartbeats'
            button class: "btn btn-mini control-students icon-hand-up #{ if @collection.selectedControlled().length is @collection.selected().length then 'active' else ''}", 'data-toggle':'button', ' Control lab'

          div class:'btn-group pull-right', ->
            button class:'btn btn-mini btn-danger icon-trash delete-students', ' Delete'
        

    template: ->

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
      @searchBox.setElement $('input#search-box')[0]
      @delegateEvents()
      @

  class Views.NewListItem extends Backbone.View
    tagName: 'tr'
    className: 'list-item'

    initialize: ->

    events:
      'click .add-item': 'addItem'
      'keydown input.email': (e)->
        console.log e.which+' pressed'
        if e.which in [9,13] and not e.shiftKey
          console.log 'calling additem'
          @addItem()

    showErrors: (model,errObj)=>
      for fieldName,err of errObj.errors
        fieldEl = @$("input.#{fieldName}")
        fieldEl.addClass('err')
        @$(".control-group.#{fieldName} .help-block").text "#{err.type}"
        fieldEl.focus()

    clearErrors: (x,y)=>
      @$('.control-group .help-block').text ''
      @collection.trigger 'saved'
      @clear().focus()

    focus: ->
      @$('input:first').focus()

    addItem: ->
      @collection.create {
        name: @$('input.name').val()
        email: @$('input.email').val()
      }, {
        wait: true
        error: @showErrors
        success: @clearErrors
      }

    clear: ->
      @$('input.name').val ''
      @$('input.email').val ''
      @

    template: ->
      td ->
        i class:'icon-caret-right'
      td ->
        i class:'icon-user'
      td ->
        div class:'control-group name', ->
          input type:'text span3', placeholder:'name', class:'name'
          span class:'help-block'
      td ->
        div class:'control-group email', ->
          input type:'text span3', placeholder:'email', class:'email'
          span class:'help-block'
      td ->
      td ->
        i class:'icon-plus add-item'

    render: ->
      super()
      console.log 'render called'
      @


  class Views.ListItem extends Backbone.View

    tagName: 'tr'
    className: 'list-item'

    initialize: ->

      @model.on 'change', =>
        
        @render()

      @model.on 'remove', @remove, @

      @model.on 'change:help', (student,help)=>
        @$el.toggleClass 'help', help
        @render()
        @model.collection.trigger 'help'
        if help then @sfx('sos')


    events:
      'click .select-item': -> @model.toggleSelect()

      'click .delete-item': ->
        dc = new UI.ConfirmDelete { model: @model }
        dc.render().open()

      'click .manage-password': ->
        managePassword = new Views.ManagePassword model:@model
        managePassword.render().open()

      'change .name': ->
        @model.save { name: @$('input.name').val() }, {
          error: @showErrors
          success: @clearErrors
        }

      'change .email': ->
        @model.save { email: @$('input.email').val() }, {
          error: @showErrors
          success: @clearErrors
        }

      'click .inc-piggyBank': -> 
        console.log 'inc', @model
        @model.changePennies(5)

      'click .dec-piggyBank': -> @model.changePennies(-5)

      'click .signin-as': -> @model.getLoginKey (err,key)-> alert(err,key)

      'click .send-email': ->
        es = new Views.EmailStudents { model: @model }
        es.render().open()

      'click .toggle-control': ->
        @model.toggleControl()

      'click .tags-list': ->
        tm = new UI.TagsModal { 
          tags: @model.get('tags'), 
          label: @model.get('name') 
          typeahead: _.difference top.app.tagList(), @model.get('tags')?.split('|') ? []
        }
        tm.render()
        tm.on 'change', (arr,str)=>
          @model.save 'tags', str
          @render()

    showErrors: (model,errObj)=>
      console.log model,errObj
      for fieldName,err of errObj.errors
        fieldEl = @$("input.#{fieldName}")
        fieldEl.addClass('err')
        @$(".control-group.#{fieldName} .help-block").text "#{err.type}"
        fieldEl.focus()

    clearErrors: (x,y)=>
      @$('.control-group .help-block').text ''
      @model.collection.trigger 'saved'

    heartBeat: ->
      @$('.icon-heart').addClass('beat')
      wait 500, =>
        @$('.icon-heart').removeClass('beat')

    renderStatus: ->
      

    template: ->
      td  ->
        i class:"#{ if @isSelected() then 'icon-check' else 'icon-check-empty' } select-item"
       td ->
        div class:"piggy-bank icon-heart #{if @get('online') then 'online' else ''}", " #{ @get 'piggyBank' }"
        div class:'btn-group hid', ->
          button class:'btn btn-mini icon-plus inc-piggyBank'
          button class:'btn btn-mini icon-minus dec-piggyBank'
      td -> 
        div class:'control-group name', ->
          input type:'text span3', value:"#{ @get 'name' }", placeholder:'name', class:'name'
          span class:'help-block name'
        span class:'tags-list span3', ->
          if @get('tags')
            for tag in @get('tags')?.split('|')
              span class:'icon-tag tag', " #{tag}"
          else span class:'icon-tags', " +tags"

      td ->
        div class:'control-group email', ->
          input type:'text span3', value:"#{ @get 'email' }", placeholder:'email', class:'email'
          span class:'help-block email'
      
        
      td ->
        div class:'btn-group hid', ->
          button class:'btn btn-mini manage-password icon-key'
          button class:'btn btn-mini signin-as icon-signin'
          button class:'btn btn-mini delete-item icon-trash'
        div class:'btn-group hid', ->
          button class:'btn btn-mini send-email icon-envelope'

      td ->
        button class:"btn btn-mini icon-hand-up toggle-control #{ if @get('control') then 'active' else ''}", 'data-toggle':'button'



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
          html: "your password is #{@model.get 'password'}" 
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

  class Views.Passwords extends Backbone.View
    tagName: 'div'
    className: 'modal fade hide'

    initialize: ->
      @collection.on 'reset', => @renderList()

    events:
      'click .generate-pws':'generatePws'
      'click .email-pws':'emailPws'


    generatePws: ->
      @collection._selected = _.pluck @collection.selected(), 'id'
      @collection.sync 'changePasswords', null, {
        ids: _.pluck @collection.selected(), 'id'
        error: (m,e)=> console.log 'error',m,e
        success: (m,e)=> 
          @collection.fetch()
      }

    emailPws: -> 
      html = """
        <p>Hello, {name}!
        </p>
        <p>
        Here is your password: {password}
        <br/>
        Click <a href='http://lingualab.io' >here to sign in</a>.
        </p>
        <b>Bye!</b>
      """
      @collection.sync 'email', null, {
        ids: _.pluck @collection.selected(), 'id'
        subject: 'Your password'
        html: html
        error: (m,e)=> console.log 'error',m,e
        success: (m,e)=> console.log 'success'
      }


    listTemplate: ->
      for stu in @selected()
        tr ->
          td "#{stu.get 'name'} (#{stu.get 'email'})"
          td class:'pw icon-key', " #{stu.get 'password'}"

    template: ->
      div class:'modal-header', ->
        h3 'Manage passwords'
      div class:'modal-body', ->
        table class:'table', ->
          

      div class:'modal-footer', ->
        div class:'btn-toolbar', ->
          button class:'btn btn-info icon-envelope email-pws', ' Email passwords'
          button class:'btn btn-warning icon-key generate-pws', ' Generate new passwords'
          button class:'btn', 'data-dismiss':'modal', ' Close'


    renderList: ->
      @$('table').html ck.render @listTemplate, @collection
      @

    render: ->
      super()
      @renderList()
      @$el.modal 'show'
      @


  class Views.EmailStudents extends Backbone.View
    tagName: 'div'
    className: 'modal hide fade emailer-view'


    templates:
      'password': """
        <p>Hello, <span class="template-field" data-fld="name">name</span>!
        </p>
        <p>
        Here is your password: <span class="template-field" data-fld="password">password</span>
        <br/>
        Click <a href='http://lingualab.io' >here to sign in</a>.
        </p>
        <b>Bye!</b>
      """
      'praise': """
        <p>Hello, <span class="template-field" data-fld="name">name</span>!</p>
        <p>
        You've been working hard outside of class. I just wanted to let you know that I
        see how much you've been practicing this week. Great job! Keep it up, I promise it'll pay off for you!
        </p>
      """

    initialize: ->

    document: document

    events:
      'click .bold': 'bold'
      'click .italic': 'italic'
      'click .underline': 'underline'
      'click .link':'link'
      'click .size':'size'
      'click ul.insert-data a':'insertFld'
      'click .send-emails':'sendEmails'
      'click .load-template': 'loadTemplate'

    sendEmails: ->
      @$('button.send-emails').button('loading')
      col = @collection ? @model.collection
      ids = if @collection then _.pluck(@collection.selected(), 'id') else [@model.id]
      col.sync 'email', null, {
        ids: ids
        subject:"important email from #{top.app.data.teacher.get 'teacherName'}"
        html: @simplifiedHTML()
        error: (m,e)=> @$('button.send-emails').button('error')
        success: (m,e)=>
          suc = new UI.FlashMessage { message: 'Sent!', cont: @$('.modal-footer') }
          suc.render()
          @$('button.send-emails').button('reset')
      }

    simplifiedHTML: ->
      body = @$('.editor-area').html()
      body = body.replace /<span class=.template-field. data-fld=.([^"]+).>[^<]*<\/span>/g, "{$1}"
      console.log body
      body

    getSelectedText: ->
      if @document?.selection
        document.selection.createRange().text
      else if @document
        document.getSelection().toString()

    selectTest: ->
      if @getSelectedText().length is 0
        alert 'Select some text first.'
        return false
      true

    exec: (type, arg = null) ->
      @document.execCommand(type, false, arg)

    query: (type) ->
      @document.queryCommandValue(type)

    bold: (e) ->
      e.preventDefault()
      @exec 'bold'

    italic: (e) ->
      e.preventDefault()
      @exec 'italic'

    underline: (e)->
      e.preventDefault()
      @exec 'underline'

    list: (e) ->
      e.preventDefault()
      @exec 'insertUnorderedList'

    link: (e) ->
      e.preventDefault()
      @exec 'unlink'
      href = prompt('Enter a link:', 'http://')
      return if not href or href is 'http://'
      href = 'http://' + href  unless (/:\/\//).test(href)
      @exec 'createLink', href

    insertFld: (e)->
      console.log e.currentTarget
      e.preventDefault()
      fld = $(e.currentTarget).attr('data-fld')
      label = $(e.currentTarget).attr('data-label')
      @exec 'insertHTML', "&nbsp;<span class='template-field' data-fld='#{fld}' contenteditable=false>#{label}</span>&nbsp;"

    size: (e)->
      e.preventDefault()
      @exec 'fontSize', $(e.target).attr('data-size')

    loadTemplate: (e)->
      e.preventDefault()
      @$('.editor-area').html @templates[$(e.currentTarget).attr('data-template')]

    template: ->
      div class:'modal-header', ->
        div class:'btn-toolbar', ->
          div class:'btn-group', ->
            button class:'btn btn-mini icon-bold bold'
            button class:'btn btn-mini icon-italic italic'
            button class:'btn btn-mini icon-underline underline'
            button class:'btn btn-mini icon-link link'
            a class:"btn btn-mini dropdown-toggle icon-text-height", 'data-toggle':"dropdown", href:"#", ->
              span class:'caret'
            ul class:'dropdown-menu', ->
              li -> a href:'#', class:'size', 'data-size':2, 'small'
              li -> a href:'#', class:'size', 'data-size':4, 'medium'
              li -> a href:'#', class:'size', 'data-size':5, 'large'


          div class:'btn-group', ->
            a class:'btn dropdown-toggle icon-user', 'data-toggle':'dropdown', href:'#', ->
              span " Student info "
              span class:'caret'
            ul class:'dropdown-menu insert-data', ->
              li -> a href:'#', class:'insert-name', 'data-label':'name', 'data-fld':'name', ->
                i class:'icon-credit-card'
                span ' Name'
              li -> a href:'#', class:'insert-email', 'data-label':'email address', 'data-fld':'email', ->
                span '@ Email Address'
              li -> a href:'#', class:'insert-password', 'data-label':'password', 'data-fld':'password', ->
                i class:'icon-key'
                span ' Password'
              li -> a href:'#', class:'insert-signin', 'data-label':'instant sign-in link (good for 10m)', 'data-fld':'signin-link', ->
                i class:'icon-signin', 
                span ' Instant sign in link'
              li -> a href:'#', class:'insert-time', 'data-label':'practice time this week', 'data-fld':'time-week', ->
                i class:'icon-time', 
                span ' Time spent practicing this week'

          div class:'btn-group', ->
            a class:'btn dropdown-toggle', 'data-toggle':'dropdown', href:'#', ->
              i class:'icon-file'
              span ' Templates '
              span class:'caret'
            ul class:'dropdown-menu', ->
              li -> a href:'#', class:'load-template', 'data-template':'password', ->
                i class:'icon-key'
                span ' Send passwords'
              li -> a href:'#', class:'load-template', 'data-template':'praise', ->
                i class:'icon-thumbs-up'
                span ' Praise'
              li -> a href:'#', class:'load-template', 'data-template':'reminder', ->
                i class:'icon-pushpin'
                span ' Reminder'


      div class:'modal-body', ->
        input type:'text', placeholder:'Subject', class:'span6'
        div class:'editor-area', ->
      div class:'modal-footer', ->
        button class:'btn pull-right', 'data-dismiss':'modal', "Close"
        button 'data-loading-text':'Sending...', 'data-complete-text':'Successfully sent!', class:'btn btn-info icon-envelope send-emails pull-left', " Send it to #{@len} #{ if @len > 1 then 'students' else 'student'}"

    render: ->
      len = if @collection? then @collection.selected().length else 1
      @$el.html ck.render @template, { len: len }
      @$el.modal('show')
      @$el.on 'shown', =>
        @trigger 'ready'
        @$('.editor-area').attr('contenteditable',true)
        @$('.editor-area').focus()
      @



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



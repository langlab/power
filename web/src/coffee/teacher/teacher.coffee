
module 'App.Teacher', (exports,top)->

  class Model extends Backbone.Model
    idAttribute: '_id'
    syncName: 'user'

    fromDB: (data)->
      {method,model,options} = data
      switch method
        when 'piggyBank'
          @set 'piggyBank', model.piggyBank

    addTags: (type,newTags)->
      log 'adding: ',type,newTags
      oldTags = @get('tags') ? {}
      
      for nt in newTags
        
        if oldTags.totals?[nt] then oldTags.totals[nt]++
        else (oldTags.totals ?= {})[nt] = 1

        if oldTags[type]?[nt] then oldTags[type][nt]++
        else (oldTags[type] ?= {})[nt] = 1

      @set 'tags', oldTags

    removeTags: (type,tagsToRemove)->
      oldTags = @get('tags')

      for tg in tagsToRemove

        if oldTags[type]?[tg]?
          oldTags[type][tg]--
          oldTags.totals[tg]--
        

      @set 'tags', oldTags





  exports.Model = Model


  exports.Views = Views = {}

  

  class Views.Profile extends Backbone.View
    tagName:'div'
    className:'modal fade hide profile-view' 

    initialize: ->


    events:
      'change input, select': (e)->
        log 'change'
        model = {}
        model[$(e.target).attr('data-fld')] = $(e.target).val()
        @model.save model, {
          error: @showErrors
          success: @saveSuccess
        }

    showErrors: (model,errs)->
      log errs
      for type,err of errs.errors
        @$(".control-group.#{type}").addClass('error')
        @$(".control-group.#{type} .help-block").text err.type

    saveSuccess: ->
      @$('.control-group').removeClass('error')
      @$('.control-group .help-block').text ''
      alert = $('<span/>').addClass('label-success').addClass('label').addClass('pull-left').text('Change saved!')
      alert.prependTo @$('.modal-footer')
      wait 1000, => alert.remove()

    template: ->
      div class:'modal-header', ->
        h1 ->
          img src:"#{ @get 'twitterImg' }"
          text " #{ @get 'twitterName' }"
      div class:'modal-body', ->
        form ->
          div class:'control-group teacherName', ->
            label 'How do students address you? (if different from your Twitter name above)'
            input type:'text', placeholder: 'your teacher name', 'data-fld':'teacherName', value:"#{ @get 'teacherName' }"
            span class:'help-block'
          div class:'control-group email', ->
            label 'Enter an email address where you can be contacted (optional).'
            input type:'text', placeholder:'your email', 'data-fld':'email', value:"#{ @get 'email' }"
            span class:'help-block'
          div class:'control-group emailPref', ->
            label 'When do you want to receive emails from lingualab.io?'
            select class:'email-pref', 'data-fld':'emailPref', ->
              option value:'never', 'Never!'
              option value:'important', 'Important notifications only'
              option value:'features', 'Notifications, new features and tips'


      div class:'modal-footer', ->
        button 'btn', 'data-dismiss':'modal', 'Close'

    render: ->
      super()
      @$el.modal('show')
      @$('select.email-pref').val(@model.get 'emailPref')
      @delegateEvents()

      @$el.on 'hidden', =>
        @remove()

      @ 


  class Views.Account extends Backbone.View
    tagName:'div'
    className:'modal fade hide account-view' 

    initialize: ->

    events:
      'click button.purchase': 'createToken'

    createToken: ->
      data =
        number: @$('input.card-number').val()
        cvc: @$('input.card-cvc').val()
        exp_month: @$('input.card-expiry-month').val()
        exp_year: @$('input.card-expiry-year').val()

      Stripe.createToken data, (status,response)=>
        log 'stripe: ', status, response
        if response.error
          @$('.errors').text response.error.message
        else
          log @model.toJSON()
          @model.sync 'charge', @model.toJSON(), {
            charge:
              amount: @$('.amount').val()
              card: response.id
              currency: 'usd'
              description: @model.id
            error: (m,err)=> log 'charge error: ',m,err
            success: (m,err)=> log 'charge success: ',m,err
          }



    template: ->
      div class:'modal-header', ->
        h2 'Account'
      div class:'modal-body', ->
        h3 "You currently have #{ @get 'piggyBank' }"
        form class:'form-inline', ->
          div class:'control-group', ->
            span "Purchase "
            input type:'text', class:'input-mini amount'
        form class:'cc', ->
          div class:'control-group card-number', ->
            input type:'text', class:'fld card-number', 'data-fld':'card-number', placeholder:'credit card number', autocomplete:'off', size:20
            span class:'help-block'
          div class:'control-group card-cvc', ->
            input type:'text', class:'fld card-cvc input-mini', 'data-fld':'card-cvc', placeholder: 'CVCC', autocomplete:'off', size:4
            span class:'help-block'
          div class:'control-group card-expiry-month', ->
            input type:'text', class:'fld input-mini card-expiry-month', 'data-fld':'card-expiry-month', placeholder: 'MM', autocomplete:'off', size:'2'
            span class:'help-block'
          div class:'control-group card-expiry-year', ->
            input type:'text', class:'fld input-small card-expiry-year', 'data-fld':'card-expiry-year', placeholder:'YYYY', autocomplete:'off', size:'4'
            span class:'help-block'

        div class:'errors', ->


      div class:'modal-footer', ->
        button class:'btn-success btn icon-credit-card purchase pull-left btn-large icon-large', " Purchase"
        button class:'btn', 'data-dismiss':'modal', ' Close'

    render: ->
      super()
      @$el.modal('show')
      @delegateEvents()
      @$el.on 'hidden', => @remove()
      @ 

  class Views.SearchBox extends Backbone.View

    events:
      'keyup': (e)->
        clearTimeout @searchWait
        @searchWait = wait 200, => @trigger 'change', $(e.target).val()
    
    initialize: ->
      @el = $('input#search-box')[0]
      @delegateEvents()



  class Views.TopBar extends Backbone.View
    tagName: 'div'
    className: 'top-bar navbar navbar-fixed-top'

    initialize: ->
      @model.on 'change:piggyBank', (m,v)=>
        log 'piggyBank change:',v
        @$('.piggyBank').text v

    events:
      'click .profile': (e)->
        log 'profile'
        top.app.views.profile.render()
        return false

      'click .heart': (e)->
        top.app.views.piggy.render()
        return false


    updateNav: (rt)->
      @$('ul.nav li').removeClass 'active'
      @$("ul.nav a[href=##{rt}]").parent('li').addClass 'active'
      @

    template: ->
      div class:'navbar-inner', ->
        div class:'container', ->
          a class:'btn btn-navbar', 'data-toggle':'collapse', 'data-target':'.nav-collapse', ->
            span class:'icon-beaker icon-large'
            span class:'icon-reorder icon-large'

          div class:'nav-collapse', ->
            ul class:'nav', ->
              li ->
                a class:'user profile', href:'#', ->
                  img src:"#{ @get 'twitterImg' }"
              li class:'divider-vertical'
              li ->
                a href:'#files', ->
                  i class:'icon-briefcase'
                  text ' Files'
              li ->
                a href:'#students', ->
                  i class:'icon-group'
                  text ' Students'

              li ->
                a href:'#lab', ->
                  i class:'icon-headphones'
                  text ' Lab'

              li ->
                a href:'#lounge', ->
                  i class:'icon-comments'
                  text ' Lounge'

            ul class:'nav pull-right', ->
              li class:'pull-left', ->
                form class:'navbar-search pull-left', ->
                  input type:'text', id:'search-box', class:'search-query span2', placeholder:'search'
              li class:'divider-vertical'
              
              li -> a href:'#', class:'heart', ->
                i class:'icon-heart'
                span class:'piggyBank', " #{ @get('piggyBank') }"
              li class:'divider-vertical'
              li -> a href:'/logout', class:'icon-signout'


            
            
    render: ->
      @$el.html ck.render @template, @model
      @


  
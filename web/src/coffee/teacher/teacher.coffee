
module 'App.Teacher', (exports,top)->

  window.filepicker.setKey('Ag4e6fVtyRNWgXY2t3Dccz')
  class Model extends Backbone.Model

  exports.Views = Views = {}

  class Views.TopBar extends Backbone.View
    tagName: 'div'
    className: 'top-bar navbar navbar-fixed-top'

    updateNav: ->
      rt = Backbone.history.fragment.split('/')[0]
      @$('ul.nav li').removeClass 'active'
      @$("ul.nav a[href=##{rt}]").parent('li').addClass 'active'
      @

    template: ->
      div class:'navbar-inner', ->
        a class:'btn btn-navbar', 'data-toggle':'collapse', 'data-target':'.nav-collapse', ->
          span class:'icon-beaker icon-large'
          span class:'icon-reorder icon-large'

        div class:'nav-collapse', ->
          ul class:'nav', ->
            li ->
              a class:'brand pull-left', href:'#', ->
                i class:'icon-bolt'
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

          ul class:'nav pull-right', ->
            li class:'user', ->
              span ->
                img src:"#{@get('twitterData').profile_image_url}"
                text " #{@get('twitterData').name} "
            li class:'divider-vertical'
            li ->
              a href:'/logout', ->
                i class:'icon-signout'
            
              

    render: ->
      @$el.html ck.render @template, @model
      @


  class exports.Controller extends top.App.Controller

    initialize: ->
      @extendRoutesWith @teacherRoutes
      
      @teacher = new Model top.app.session.user
      @filez = new App.File.Collection()
      @students = new App.Student.Collection()

      @views =
        topBar: new Views.TopBar { model: @teacher }
        filez: new App.File.Views.Main { collection: @filez }
        students: new App.Student.Views.Main { collection: @students }
        lab: new App.Lab.Views.Main

      @filez.on 'selected', (model)=>
        @navigate "files/#{model.id}", true

      @fromDB()
      @showTopBar()

    teacherRoutes:
      '/':'home'
      'files':'files'
      'students':'students'
      'files/:id':'fileDetail'
      'lab':'lab'

    fromDB: ->
      @io = top.app.sock

      @io.on 'sync', (service, data)=>
        console.log 'service',service,'data',data
        if service is 'file'
          @filez.fromDB(data)

    showTopBar: ->
      @views.topBar.render().open()

    home: ->
      @clearViews()
      @views.layout = new App.Layout.Main
      @views.layout.render().open()

    files: ->
      @clearViews 'topBar'
      @views.topBar.updateNav()
      @views.filez.render().open()

    fileDetail: (id)->
      @clearViews 'topBar'
      @views.detailView = new App.File.Views.Detail { model: @filez.get(id) }
      @views.detailView.render().open()

    students: ->
      @clearViews 'topBar'
      @views.topBar.updateNav()
      @views.students.render().open()

    lab: ->
      @clearViews 'topBar'
      @views.topBar.updateNav()
      @views.lab.render().open()

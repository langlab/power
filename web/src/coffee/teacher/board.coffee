
module 'App.Board', (exports,top)->
  
  exports.Views = Views = {}

  class Views.Input extends Backbone.View
    className:'modal fade hide'
    tagName: 'div'

    initialize: (@options)->
      @on 'open', =>
        @$el.modal 'show'
        @$el.on 'shown', =>
        @$el.on 'hidden', =>
          @unbind()
          @remove()

    events:
      'click .save': 'save'
      'click .cancel':'close'
      'click .btn': (e)-> e.preventDefault()


    save: ->
      data =
        label: @$('.label').val()
        placeholder: @$('.placeholder').val()
        size: @$('.size .active').attr('data-val')
        answer: @$('.answer').val()
        feedbacks: []

      for el in @$('.feedback')
        data.feedbacks.push {
          expr: $(el).find('.match').val()
          feedback: $(el).find('.fb').val()
        }

      @trigger 'save', data

      @close()

    close: ->
      @$el.modal 'hide'

    template: ->
      div class:'modal-header', ->
        h3 "Insert question input"
      div class:'modal-body', style:'max-height:300px;', ->
        form class:'form-horizontal', ->
          div class:'control-group', ->
            label class:'control-label', "Question or label"
            div class:'controls', -> 
              input type:'text', class:'label', value:"#{@options.label}"
              div class:'help-block', "(this is for you, student won't see this)"
          div class:'control-group', ->
            label class:'control-label', "Placeholder text"
            div class:'controls', -> 
              input type:'text', class:'placeholder'
              div class:'help-block', "This will show up inside the input"
          div class:'control-group size', ->
            label class:'control-label', 'Size'
            div class:'btn-group controls', 'data-toggle':'buttons-radio', ->
              button class:'btn', 'data-val':'small', "Small"
              button class:'btn active', 'data-val':'medium', "Medium"
              button class:'btn', 'data-val':'large', "Large"
          div class:'control-group', ->
            label class:'control-label', "Correct answer(s)"
            div class:'controls', -> 
              input class:'answer', type:'text'
              div class:'help-block', "You may use regular expressions to match many responses"

        table class:'table', ->
          tr -> td colspan:2, "Give feedback..."
          for i in [1..3]
            tr class:'feedback', ->
              td -> input type:'text', class:'match', placeholder:'when answer matches'
              td -> input type:'text', class:'fb', placeholder:'feedback to student'


      div class:'modal-footer', ->
        button class:'btn btn-success icon-ok save', " Insert question input"


  class Views.TTS extends Backbone.View
    className:'modal fade hide'
    tagName: 'div'

    languages: 
      eng: 'English'
      fr: 'Français'
      spa: 'Español'
      ger: 'Deutch'
      ita: 'Italiano'


    initialize: (@options)->

      _.defaults @options, {
        gender: 'f'
        language: 'eng'
        rate: ''
        textToSay: ''
      }

      @on 'open', =>
        @$el.modal 'show'
        @$el.on 'shown', =>
          @$('input').focus()
        @$el.on 'hidden', =>
          @unbind()
          @remove()

    events:
      'click .save': 'save'
      'click .try-it': 'tryIt'
      'click .cancel':'close'
      'click .btn': (e)-> e.preventDefault()


    save: ->
      @trigger 'save', {
        language: @$('.language .active').attr('data-val')
        gender: @$('.gender .active').attr('data-val')
        textToSay: @$('.text-to-say').val()
        rate: @$('.rate').val()
      }

      @close()


    close: ->
      @$el.modal 'hide'


    tryIt: (e)->
      e.preventDefault()
      console.log('hi')
      @tts {
        language: @$('.language .active').attr('data-val')
        gender: @$('.gender .active').attr('data-val')
        textToSay: @$('.text-to-say').val()
        rate: @$('.rate').val()
      }

    template: ->
      div class:'modal-header', ->
        h3 "Insert pronunciation"
      div class:'modal-body', ->
        form  ->
          div class:'control-group', ->
            label "Text to speak"
            input type:'text', class:'text-to-say', value:"#{@options.textToSay}"
          div class:'control-group', ->
            label "Language"
            div class:'btn-group language', 'data-toggle':'buttons-radio', ->
              for lang,label of @languages
                button 'data-val':"#{lang}", class:"btn #{if @options.language is lang then 'active' else ''}", " #{label}"
          div class:'control-group', ->
            label "Gender"
            div class:'btn-group gender', 'data-toggle':'buttons-radio', ->
              button 'data-val':'f', class:"btn #{if @options.gender isnt 'm' then 'active' else ''}", " Female"
              button 'data-val':'m', class:"btn #{if @options.gender is 'm' then 'active' else ''}", " Male"
          div class:'control-group', ->
            label "Speed"
            select class:'rate', ->
              option value:'', "Normal"
              option value:'slow', "Slow"
              option value:'fast', "Fast"

          button class:'btn try-it icon-comment-alt', " Try it!"
      div class:'modal-footer', ->
        button class:'btn cancel', " Cancel"
        button class:'btn btn-success icon-ok save', " Insert audio"

    render: ->
      @$el.html ck.render @template, @
      @




  class Views.Main extends Backbone.View
    tagName: 'div'
    className: 'lab-whiteboard'

    initialize: (@options)->
      @model.on 'change:visible', =>
        @$('.accordion-group').toggleClass('visible')
        @$('.toggle-visible').toggleClass('icon-eye-close').toggleClass('icon-eye-open')
        @$('.editor-area').toggleClass('visible')

      @on 'open', =>
        @trigger 'ready'
        @$('.editor-area').attr('contenteditable',true)
        @$('.editor-area').html @model.get('html') or ''
        @$('.editor-area').focus()


    update: ->
      @model.set 'html', @simplifiedHTML()

    document: document

    events:
      'keyup .editor-area':'update'
      'click button, a':'update'
      'click .accordion-group': -> @model.set 'open', not @model.get('open')
      'click .toggle-visible': (e)->
        e.stopPropagation()
        @model.set 'visible', not @model.get('visible')
      'click .bold': 'bold'
      'click .italic': 'italic'
      'click .underline': 'underline'
      'click .link':'link'
      'click .size':'size'
      'click .insert-input':'insertInput'
      'click .insert-table':'insertTable'
      'click .insert-tts':'insertTTS'

      'click .wb-tts i': (e)->
        v = new Views.TTS(JSON.parse Base64.decode $(e.currentTarget).parent().attr('data-config'))
        v.render().open()

    simplifiedHTML: ->
      body = @$('.editor-area').html()
      body

    getSelectedText: ->
      if @document?.selection
        document.selection.createRange().text
      else if @document
        document.getSelection().toString()

    getSelectedHtml: ->
      if @document?.selection
        document.selection.createRange().html

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

    insertInput: (e)->
      e.preventDefault()
      selectedText = @getSelectedText()
      data =
        label: selectedText
        placeholder: ''
        size: 'span6'
        answer: ''
      
      @exec 'insertHTML', "&nbsp;<span class='temp-hold wb-input'><input type='text' class='#{data.size}' /></span>&nbsp;"

      v = new Views.Input { label: data.label }
      v.render().open()

      v.on 'save', (data)=>
        console.log data
        @$('.temp-hold input')
          .attr('placeholder',data.placeholder)
          .removeClass().addClass("input-#{data.size}")

        @$('.temp-hold')
          .attr('data-config',Base64.encode JSON.stringify data)
          .removeClass('temp-hold')
          .attr('contenteditable',false)


        @update()



    insertTable: (e)->
      console.log e.currentTarget
      e.preventDefault()
      #fld = $(e.currentTarget).attr('data-fld')
      #label = $(e.currentTarget).attr('data-label')
      @exec 'insertHTML', "&nbsp;<table class='table table-condensed table-bordered'><tr><td>1</td><td>2</td></tr></table>&nbsp;"

    insertTTS: (e)->
      selectedText = @getSelectedText()
      data =
        textToSay: selectedText
        language: 'eng'
        gender: 'f'
        rate: ''
      
      @exec 'insertHTML', "&nbsp;<span contenteditable=false data-config='#{Base64.encode JSON.stringify data}' class='wb-tts temp-hold'>#{selectedText}</span>&nbsp;"
      
      v = new Views.TTS { textToSay: data.textToSay }
      v.render().open()
      v.on 'save', (data)=>
        @$('.temp-hold')
          .attr('data-config',Base64.encode JSON.stringify data)
          .removeClass('temp-hold')
          .attr('contenteditable',false)
          .html "#{if selectedText then data.textToSay+' ' else ''}<i class='icon-volume-up'/>"
        @update()



    link: (e) ->
      e.preventDefault()
      @exec 'unlink'
      href = prompt('Enter a link:', 'http://')
      return if not href or href is 'http://'
      href = 'http://' + href  unless (/:\/\//).test(href)
      @exec 'createLink', href

    size: (e)->
      e.preventDefault()
      @exec 'fontSize', $(e.target).attr('data-size')

    loadTemplate: (e)->
      e.preventDefault()
      @$('.editor-area').html @templates[$(e.currentTarget).attr('data-template')]

        
    template: ->
      div class:"accordion-group #{if @model.get('visible') then 'visible' else ''}", ->
        div class:'accordion-heading', ->
          span class:'accordion-toggle icon-edit', 'data-toggle':'collapse', 'data-target':".lab-wb-#{ @label }", ->
            text " Whiteboard #{ @label }"
            span class:'btn-group pull-right', ->
              
        div class:"collapse#{ if @model.get('open') then ' in' else '' } lab-wb-#{ @label } accordion-body", ->
          div class:'accordion-inner wb-cont', ->
            div class:"wb-cont-#{ @label }", ->
              div class:'wb-header', ->
                div class:'btn-toolbar', ->
                  div class:'btn-group pull-right right-group', ->
                    button class:"btn btn-mini icon-eye-#{ if @model?.get('visible') then 'open active' else 'close' } toggle-visible"
                  div class:'btn-group pull-left left-group', ->
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
                    button class:'btn btn-mini icon-question-sign insert-input'
                    button class:'btn btn-mini icon-table insert-table'
                    button class:'btn btn-mini icon-comment-alt insert-tts'
              div class:'wb-body', ->
                div class:'editor-area', contenteditable:'true', ->


    render: ->
      @$el.html ck.render @template, @options
      @$('.editor-area').toggleClass 'visible', @model.get 'visible'
      @delegateEvents()
      @

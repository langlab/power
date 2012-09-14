
module 'App.Board', (exports,top)->
  
  exports.Views = Views = {}

  class Views.Input extends Backbone.View
    className:'modal fade hide'
    tagName: 'div'

    initialize: (@options)->
      teacherPrefs = app.data.teacher.get('prefs')

      _.defaults @options, {
        label: ''
        placeholder: ''
        size: 'medium'
        kb: teacherPrefs?.keyboard
        answer: ''
        correctFeedback: teacherPrefs?.correctFeedback
        feedbacks: []
        notifyCorrect: teacherPrefs?.notifyCorrect
        notifyAlmost: teacherPrefs?.notifyAlmost
        useRegex: teacherPrefs?.useRegex
        caseSensitive: false
      }
        
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
      'click .notify-correct': (e)->
        @options.notifyCorrect = not @options.notifyCorrect
        $(e.currentTarget).toggleClass('icon-check-empty').toggleClass('icon-check')
      'click .notify-almost': (e)->
        @options.notifyAlmost = not @options.notifyAlmost
        $(e.currentTarget).toggleClass('icon-check-empty').toggleClass('icon-check')
      'click .use-regex': (e)->
        @options.useRegex = not @options.useRegex
        $(e.currentTarget).toggleClass('icon-check-empty').toggleClass('icon-check')


    save: ->
      data =
        id: moment().valueOf()
        label: @$('.question').val()
        placeholder: @$('.placeholder').val()
        size: @$('.size .active').attr('data-val')
        kb: @$('.kb .active').attr('data-val')
        answer: @$('.answer').val()
        correctFeedback: @$('.correctFeedback').val()
        notifyCorrect: @$('.notify-correct').hasClass('icon-check')
        notifyAlmost: @$('.notify-almost').hasClass('icon-check')
        useRegex: @$('.use-regex').hasClass('icon-check')
        feedbacks: []

      prefs = app.data.teacher.get('prefs') ? {}
      _.extend prefs, {
        keyboard: data.kb
        correctFeedback: data.correctFeedback
        useRegex: data.useRegex
        notifyCorrect: data.notifyCorrect
        notifyAlmost: data.notifyAlmost
      }
      app.data.teacher.save('prefs',prefs)


      for el in @$('.feedback')
        data.feedbacks.push {
          expr: $(el).find('.expr').val()
          fb: $(el).find('.fb').val()
        }

      @trigger 'save', data

      @close()

    close: ->
      @$el.modal 'hide'

    template: ->
      div class:'modal-header', ->
        h4 "Short answer question input"
      
      div class:'modal-body', style:'max-height:26px;overflow-y:hidden;', ->
        ul class:'nav nav-tabs', ->
          li class:'active', -> a href:'#input-tab-appearance', 'data-toggle':'tab', "Appearance"
          li -> a href:'#input-tab-answer', 'data-toggle':'tab', "Answer"
          li -> a href:'#input-tab-feedback', 'data-toggle':'tab', "Feedback"
          li -> a href:'#input-tab-auto-grading', 'data-toggle':'tab', "Auto-Grading"
          li -> a href:'#input-tab-try-it', 'data-toggle':'tab', "Try It!"
      
      div class:'modal-body', style:'max-height:300px;overflow-y:auto;', ->  
  
        div class:'tab-content', ->
          
          div class:'tab-pane active', id:'input-tab-appearance', ->
            form class:'form-horizontal', ->
              div class:'control-group', ->
                label class:'control-label', "Question or label"
                div class:'controls', -> 
                  input type:'text', class:'question', value:"#{@options.label}", rel:'tooltip', 'data-original-title':"(this is for you, student won't see this)"
              div class:'control-group', ->
                label class:'control-label', "Placeholder text"
                div class:'controls', -> 
                  input type:'text', class:'placeholder', value:"#{@options.placeholder}"
              div class:'control-group size', ->
                label class:'control-label', 'Size'
                div class:'btn-group controls size', 'data-toggle':'buttons-radio', ->
                  button class:"btn btn-small #{if @options.size is 'small' then 'active' else ''}", 'data-val':'small', "Small"
                  button class:"btn btn-small #{if @options.size is 'medium' then 'active' else ''}", 'data-val':'medium', "Medium"
                  button class:"btn btn-small #{if @options.size is 'large' then 'active' else ''}", 'data-val':'large', "Large"
              div class:'control-group kb', ->
                label class:'control-label', 'Provide special characters keyboard?'
                div class:'btn-group controls', 'data-toggle':'buttons-radio', ->
                  button class:"btn btn-small #{if not @options.kb then 'active' else ''}", 'data-val':'', "None"
                  button class:"btn btn-small #{if @options.kb is 'spa' then 'active' else ''}", 'data-val':'spa', "Español"
                  button class:"btn btn-small #{if @options.kb is 'fr' then 'active' else ''}", 'data-val':'fr', "Français"
                  button class:"btn btn-small #{if @options.kb is 'ita' then 'active' else ''}", 'data-val':'ita', "Italiano"
                  button class:"btn btn-small #{if @options.kb is 'ger' then 'active' else ''}", 'data-val':'ger', "Deutsch"
          
          div class:'tab-pane', id:'input-tab-answer', ->
            
            div class:'controls', ->
              div class:"icon-check#{if @options.useRegex then '' else '-empty'} use-regex", ->
                span " Use "
                a href:"#", "magic matching"
                span "?"
              
            table class:'table table-condensed table-hover', ->
              thead ->
                tr -> 
                  th "answer is correct when it matches:"
                  th "give positive feedback:"
                
              tbody ->
                tr ->
                  td -> 
                    input class:'answer icon-ok', type:'text', value:"#{@options.answer}", placeholder:'string or magic match'
                  td -> 
                    input type:'text', class:'correctFeedback', placeholder:'feedback when correct', value:"#{@options.correctFeedback ? ''}"
            

          div class:'tab-pane', id:'input-tab-feedback', ->
            div class:'controls', ->
              div class:"icon-check#{if @options.notifyCorrect then '' else '-empty'} notify-correct", ->
                span " Notify student when correct?"
              div class:"icon-check#{if @options.notifyAlmost then '' else '-empty'} notify-almost", ->
                span " Notify student when answer is ALMOST correct?"

            table class:'table table-condensed table-hover', ->
              thead ->
                tr -> 
                  th "when incorrect and matches..."
                  th "give this feedback"
              tbody ->
                for i in [0..2]
                  tr class:'feedback', ->
                    td -> input type:'text', class:'expr', placeholder:'string or regular expression', value:"#{@options.feedbacks[i]?.expr ? ''}"
                    td -> input type:'text', class:'fb', placeholder:'feedback', value:"#{@options.feedbacks[i]?.fb ? ''}"

          div class:'tab-pane', id:'input-tab-auto-grading', ->
            h3 'auto grading stuff'

          div class:'tab-pane', id:'input-tab-try-it', ->
            h3 'input preview'

      div class:'modal-footer', ->
        button class:'btn btn-small btn-danger icon-trash, pull-right', " Delete"
        button class:'btn btn-small btn-success icon-ok save pull-left', " Save and close"


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
        rate: @$('.rate .active').attr('data-val')
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
        rate: @$('.rate .active').attr('data-val')
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
            div class:'btn-group rate', 'data-toggle':'buttons-radio', ->
              button 'data-val':'normal', class:"btn #{if not (@options.rate in ['slow','fast']) then 'active' else ''}", " Normal"
              button 'data-val':'slow', class:"btn #{if @options.rate is 'slow' then 'active' else ''}", " Slow"
              button 'data-val':'fast', class:"btn #{if @options.rate is 'fast' then 'active' else ''}", " Fast"

          
      div class:'modal-footer', ->
        button class:'btn btn-info try-it icon-volume-up pull-left', " Try it!"
        button class:'btn btn-success icon-ok save', " Save"

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

      'click .wb-tts': (e)->
        @editTTS $(e.currentTarget)

      'click .wb-input': (e)-> 
        @editInput $(e.currentTarget)

      'click .submit': (e)->
        @model.set 'state', 'submit'
        @model.set 'state', ''

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

    insertTable: (e)->
      console.log e.currentTarget
      e.preventDefault()
      #fld = $(e.currentTarget).attr('data-fld')
      #label = $(e.currentTarget).attr('data-label')
      @exec 'insertHTML', "&nbsp;<table class='table table-condensed table-bordered'><tr><td>1</td><td>2</td></tr></table>&nbsp;"



    editInput: ($inputEl)->

      v = new Views.Input(JSON.parse Base64.decode $inputEl.attr('data-config'))
      v.render().open()

      v.on 'save', (data)=>
        console.log data
        $inputEl.find('input')
          .attr('placeholder',data.placeholder)
          .removeClass().addClass("input-#{data.size}")

        $inputEl
          .attr('data-config',Base64.encode JSON.stringify data)
          .attr('contenteditable',false)

        @update()

    insertInput: (e)->
      e.preventDefault()
      selectedText = @getSelectedText()
      data =
        label: selectedText
        placeholder: ''
        size: 'medium'
        answer: ''
        feedback: []
      
      elId = moment().valueOf()
      @exec 'insertHTML', "&nbsp;<span id='#{elId}' class='wb-input' data-config='#{Base64.encode JSON.stringify data}'><input type='text' class='#{data.size}' /><span class='notify'></span></span>&nbsp;"

      $inputEl = @$("##{elId}")
      @editInput($inputEl)


    editTTS: ($ttsEl)->
      v = new Views.TTS(JSON.parse Base64.decode $ttsEl.attr('data-config'))
      v.render().open()
      v.on 'save', (data)=>
        $ttsEl
          .attr('data-config',Base64.encode JSON.stringify data)
          .attr('contenteditable',false)
          .html "<i class='icon-cont icon-volume-up' /><span class='spinner'></span>"
        @update()


    insertTTS: (e)->
      selectedText = @getSelectedText()
      data =
        textToSay: selectedText
        language: 'eng'
        gender: 'f'
        rate: ''
      
      elId = moment().valueOf()
      @exec 'insertHTML', "&nbsp;<span id='#{elId}' contenteditable=false data-config='#{Base64.encode JSON.stringify data}' class='wb-tts temp-hold'>#{selectedText}</span>&nbsp;"
      $ttsEl = @$("##{elId}")
      @editTTS($ttsEl)

      



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
                  div class:'btn-group', ->
                    button rel:'tooltip', title:'insert a question input', class:'btn dropdown-toggle btn-mini icon-question-sign', 'data-toggle':'dropdown', href:'#', ->
                      span " "
                      span class:'caret'
                    ul class:'dropdown-menu', ->
                      li -> a href:'#', class:'insert-input', 'short answer'
                      li -> a href:'#', 'long answer'
                      li -> a href:'#', 'multiple choice'
                    #button rel:'tooltip', title:'insert an', class:'btn insert-input'
                    #button class:'btn btn-mini icon-table insert-table'
                    button rel:'tooltip', title:'insert text-to-speech pronunciation', class:'btn btn-mini icon-comment-alt insert-tts'
                  div class:'btn-group', ->
                    button rel:'tooltip', title:'collect student responses', class:'btn btn-mini icon-download-alt submit' 

              div class:'wb-body', ->
                div class:'editor-area', contenteditable:'true', ->


    render: ->
      @$el.html ck.render @template, @options
      @$('.editor-area').toggleClass 'visible', @model.get 'visible'
      @$('[rel=tooltip]').tooltip()
      @delegateEvents()
      @

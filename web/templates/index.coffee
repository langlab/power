doctype 5
html(lang="en")

  head
    title 'hi'
    

  body
    #main

    script(type='text/javascript',src='http://api.lingualab.io/socket.io/socket.io.js')
    - var scr = "<script> window.sess = JSON.parse('"+ JSON.stringify(sess) +"');</script>"
    !{scr}

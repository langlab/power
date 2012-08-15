fs = require 'fs'
{EventEmitter} = require 'events'
{spawn, exec} = require 'child_process'
hound = require 'hound'
sty = require 'sty'


class wProc extends EventEmitter
  
  constructor: (@options)->
    # options are:
    # - cmd : command to run
    # - path : where to watch for changes
    # - startMsg : message to log on command start/restart

  start: ->
    @cp = exec @options.cmd, @options.opts

    @cp.stdout.on 'data', (data)=> @msgLog(data)
    @cp.stderr.on 'data', (data)=> @errLog(data)
    @cp.on 'exit', (code)=>
      if not @options.path
        @msgLog("#{@options.cmd} exited with code #{code}")
    @

  restart: ->
    @cp.kill()
    @cp.on 'exit', =>
      @start()
      if msg = @options.startMsg then @msgLog msg
    @cp.off 'exit'
    @

  watch: ->
    @watcher = new hound.watch @options.path
    @watcher.on 'create', (file,stats)=>
      @msgLog "#{file} created."
      @trigger 'file:create', { file:file, stats:stats }
      @restart()

    @watcher.on 'change', (file,stats)=>
      @msgLog "#{file} changed."
      @trigger 'file:change', { file:file, stats:stats }
      @restart()

    @watcher.on 'delete', (file)=>
      @msgLog "#{file} deleted."
      @trigger 'file:delete', { file:file }
      @restart()
    @

  msgLog: (data)->
    #if /error/.test(data) then @errLog(data)
    console.log sty.green data
    @trigger 'proc:msg', { proc: @options.cmd, pid: @options.pid, msg: data }
    @

  errLog: (data)->
    @beep()
    console.log sty.red data
    @trigger 'proc:error', { proc: @options.cmd, pid: @options.pid, error: data }
    @

  beep: -> 
    spawn "printf '\a'"
    @

  trigger: (ev,data)->
    @emit ev, data
    @emit 'all', ev, data

procs = {
  #api:
    #server: new wProc { cmd: 'cd ./api; supervisor -w ./  -n error api.coffee' }
  
  #web:
    #server: new wProc { cmd: 'cd ./web; supervisor -w ./ -i ./pub  -n error web.coffee' }

  script:
    common: new wProc { cmd: 'coffee -j ./web/pub/js/common.js -wc ./web/src/coffee/common/'}
    teacher: new wProc { cmd: 'coffee -j ./web/pub/js/teacher.js -wc ./web/src/coffee/teacher/'}
    student: new wProc { cmd: 'coffee -j ./web/pub/js/student.js -wc ./web/src/coffee/student/'}
    welcome: new wProc { cmd: 'coffee -j ./web/pub/js/login.js -wc ./web/src/coffee/login/'}

  #style:
    #all: new wProc { cmd: 'supervisor -w ./web/src/styl -n exit -x stylus -o ./web/pub/css ./web/src/styl/index.styl'}
}


task 'dev', ->
  for gnm,grp of procs
    for pnm,proc of grp
      proc.start()
      if proc.path then proc.watch()












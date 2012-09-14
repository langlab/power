{spawn,exec} = require 'child_process'
_ = require 'underscore'


class TRE

  @compare: (data, cb)->

    {re, str, caseSensitive, literal} = data

    if not _.isArray str then str = [str]

    proc = exec "agrep -s#{if caseSensitive then '' else ' -i'}#{if literal then '-k' else ''} -9 '#{re}'"

    console.log str.join('\n')
    proc.stdin.end str.join('\n')
    
    proc.stdout.on 'data', (data)->
      res = []
      for line in data.toString().split('\n')
        rec = line.split(':')
        if rec[1] then res.push { str: rec[1], edits: rec[0] }
      console.log res
      cb null, res

    proc.stderr.on 'data', (err)->
      cb err, null

    proc.on 'exit', (code)->

module.exports = TRE




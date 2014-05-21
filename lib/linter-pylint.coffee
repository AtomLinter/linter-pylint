linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

{exec} = require 'shelljs'

class LinterPylint extends Linter
  @syntax: 'source.py' # fits all *.py-files
  @enabled: false # false until executable checked
  cmd: 'pylint'
  options: [
    "--msg-template='{line};;{column};;{category};;{msg}'",
    "--reports=n",
    "--disable=all",
    "--enable=w,e"
  ]
  linterName: 'pylint'

  regex: '(?<line>\\d+);;(?<column>\\d+);;((?<error>error)|(?<warning>warning));;(?<message>.*)$'

  constructor: (editor) ->
    super(editor)
    exec cmd + ' --version', @executionCheckHandle

  executionCheckHandle: (error, stdout, stderr) =>
    versionRegEx = /pylint ([\d\.]+)\,/
    if error > 0
      console.error "Linter-PyLint: 'pylint' was not executable: " + stdout ? stderr
    else
      console.log "Linter-Pylint: found pylint " + versionRegEx.exec(stdout)[1]

  lintFile: (filePath, callback) ->
    if @enabled
      exec @getCmd(filePath) + ' ' + options.join(' '), (error, stdout, stderr) =>
        @processMessage(stdout, callback)


module.exports = LinterPylint

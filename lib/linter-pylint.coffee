{exec, child} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"


class LinterPylint extends Linter
  @syntax: 'source.py' # fits all *.py-files
  @enabled = false # false until executable checked
  @initialized = false # false until initialized
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
    @initialize() # initialize first
    super(editor)

  # Private: grants the existance and accesibility of the linter-executable
  #
  # Does a '--version'-call on the linter and installs a corresponding handler.
  initialize: =>
    exec(cmd + ' --version', @executionCheckHandler) unless @initialized
    @initialized = true
    console.log 'Linter-Pylint: initialization completed'

  # Private: handles the initial 'version' call, extracts the version and
  # enables the linter
  executionCheckHandler: (error, stdout, stderr) =>
    versionRegEx = /pylint ([\d\.]+)\,/
    if error > 0
      console.error "Linter-PyLint: 'pylint' was not executable: " + stdout ? stderr
    else
      console.log "Linter-Pylint: found pylint " + versionRegEx.exec(stdout)[1]
      @enabled = true # everything is fine, the linter is ready to work

  lintFile: (filePath, callback) ->
    @initialize() unless @initialized # initialize first - inserted for debugging
    if @enabled # disabled if the lint-executable is not reachable - see initialization
      exec(@getCmd(filePath) + ' ' + options.join(' '), (error, stdout, stderr) =>
        @processMessage(stdout, callback))


module.exports = LinterPylint

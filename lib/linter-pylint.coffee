{exec, child} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"


class LinterPylint extends Linter
  @enabled = false # false until executable checked
  @syntax: 'source.python' # fits all *.py-files
  cmd: "pylint --msg-template='{line},{column},{category},{msg}' --reports=n"

  linterName: 'pylint'

  regex: '^(?<line>\\d+),(?<col>\\d+),((?<error>error)|(?<warning>warning)),(?<message>.*)$'
  regexFlags: 'm'

  constructor: (@editor) ->
    exec 'pylint --version', @executionCheckHandler
    console.log 'Linter-Pylint: initialization completed'

  # Private: handles the initial 'version' call, extracts the version and
  # enables the linter
  executionCheckHandler: (error, stdout, stderr) =>
    versionRegEx = /pylint ([\d\.]+)\,/
    if not versionRegEx.test(stdout)
      console.error "Linter-Pylint: 'pylint' was not executable: " + stdout ? stderr
    else
      console.log "Linter-Pylint: found pylint " + versionRegEx.exec(stdout)[1]
      @enabled = true # everything is fine, the linter is ready to work

  lintFile: (filePath, callback) =>
    if @enabled # disabled if the lint-executable is not reachable - see initialization
      exec @getCmd(filePath), {cwd: @cwd}, (error, stdout, stderr) =>
        @processMessage(stdout, callback)

module.exports = LinterPylint

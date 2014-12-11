{exec} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
{log, warn} = require "#{linterPath}/lib/utils"


class LinterPylint extends Linter
  @syntax: 'source.python' # fits all *.py-files

  linterName: 'pylint'

  regex: '^(?<line>\\d+),(?<col>\\d+),\
          ((?<error>error)|(?<warning>warning)),\
          (?<msg_id>\\w\\d+):(?<message>.*)$'
  regexFlags: 'm'

  constructor: (@editor) ->
    super @editor

    # sets @cwd to the dirname of the current file
    # if we're in a project, use that path instead
    @cwd = atom.project.path ? @cwd

    # Set to observe config options
    atom.config.observe 'linter-pylint.executable', => @updateCommand()
    atom.config.observe 'linter-pyling.rcFile', => @updateCommand()

  destroy: ->
    atom.config.unobserve 'linter-pylint.Executable'
    atom.config.unobserve 'linter-pyling.rcFile'

  # Sets the command based on config options
  updateCommand: ->
    cmdOptions = ["--msg-template='{line},{column},{category},{msg_id}:{msg}'"
                  '--reports=n']
    executable = atom.config.get 'linter-pylint.executable'
    rcFile = atom.config.get 'linter-pylint.rcFile'

    if rcFile
      cmdOptions.push "--rcfile=#{rcFile}"

    if executable
      cmd = ["#{executable}"].concat cmdOptions
    else
      cmd = ["pylint"].concat cmdOptions

    @cmd = cmd


module.exports = LinterPylint

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
    atom.config.observe 'linter-pylint.rcFile', => @updateCommand()

  destroy: ->
    atom.config.unobserve 'linter-pylint.executable'
    atom.config.unobserve 'linter-pylint.rcFile'

  # Sets the command based on config options
  updateCommand: ->
    cmd = [atom.config.get 'linter-pylint.executable']
    cmd.push "--msg-template='{line},{column},{category},{msg_id}:{msg}'"
    cmd.push '--reports=n'

    rcFile = atom.config.get 'linter-pylint.rcFile'
    if rcFile
      cmd.push "--rcfile=#{rcFile}"

    console.log cmd

    @cmd = cmd


module.exports = LinterPylint

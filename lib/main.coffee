{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'
path = require 'path'
_ = require 'lodash'
os = require 'os'

module.exports =
  config:
    executable:
      type: 'string'
      default: 'pylint'
      description: 'Command or path to executable. Use %p for current project directory (no trailing /).'
    pythonPath:
      type: 'string'
      default: '%(PYTHONPATH), %f, %p'
      description: 'Comma delimited list of paths to set $PYTHONPATH to. Use %p for current project directory,
        %f for the directory of the current file, or %(VAR_NAME) to use a pre-existing environment variable.'
    rcFile:
      type: 'string'
      default: ''
      description: 'Path to pylintrc file. Use %p for current project directory, %f for the directory of the
        current file, or %(VAR_NAME) to use a pre-existing environment variable.'
    workingDirectory:
      type: 'string'
      default: '%p'
      description: 'Directory pylint is run from. Use %p for current project directory, %f for the directory of
        the current file, or %(VAR_NAME) to use a pre-existing environment variable.'
    messageFormat:
      type: 'string'
      default: '%i %m'
      description: 'Format for Pylint messages where %m is the message, %i is the numeric mesasge ID
        (e.g. W0613) and %s is the human-readable message ID (e.g. unused-argument).'

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-pylint.executable',
      (newExecutableValue) =>
        @executable = newExecutableValue
    @subscriptions.add atom.config.observe 'linter-pylint.rcFile',
      (newRcFileValue) =>
        @rcFile = newRcFileValue
    @subscriptions.add atom.config.observe 'linter-pylint.messageFormat',
      (newMessageFormatValue) =>
        @messageFormat = newMessageFormatValue
    @subscriptions.add atom.config.observe 'linter-pylint.pythonPath',
      (newPythonPathValue) =>
        @pythonPath = _.trim newPythonPathValue, path.delimiter
    @subscriptions.add atom.config.observe 'linter-pylint.workingDirectory',
      (newCwd) =>
        @cwd = _.trim newCwd, path.delimiter

    @regex = '(?<line>\\d+),(?<col>\\d+),(?<type>\\w+),(\\w\\d+):(?<message>.*)\\r?(\\n|$)'
    @messageFormatFlags =
      i: '{msg_id}',
      m: '{msg}',
      s: '{symbol}'

    @errorWhitelist = [
      /^No config file found, using default configuration$/
    ]

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      name: 'Pylint'
      grammarScopes: ['source.python']
      scope: 'file'
      lintOnFly: true
      lint: (activeEditor) =>
        file = activeEditor.getPath()

        return helpers.tempFile path.basename(file), activeEditor.getText(), (tmpFilename) =>
          # default project dir to file directory if path cannot be determined
          fileDir = path.dirname(file)
          replaceFlags =
            f: fileDir
            p: @getProjDir(file) or fileDir

          # Replace special flags in user configurable values
          cwd = @replaceVars(@cwd, replaceFlags, process.env)
          executable = @replaceVars(@executable, replaceFlags, process.env)
          format = @replaceVars(@messageFormat, @messageFormatFlags, {})
          pythonFlags = @replaceVars(@pythonPath, replaceFlags, process.env).replace(/\s*,\s*/g, path.delimiter)

          # Construct arguments for pylint
          args = [
            "--msg-template='{line},{column},{category},{msg_id}:#{format}'"
            '--reports=n'
            '--output-format=text'
          ]

          if @rcFile
            rcFile = @replaceVars(@rcFile, replaceFlags, process.env)
            args.push "--rcfile=#{rcFile}"

          args.push tmpFilename

          # Warning: This may cause to pylint to crash if a file exists in any of the path that
          # shadows standard library imports pylint and its dependencies use such as keyword.py
          env = Object.create process.env,
            PYTHONPATH:
              value: pythonFlags
              enumerable: true

          return helpers.exec(executable, args, {env: env, cwd: cwd, stream: 'both'}).then (data) =>
            filteredErrors = @filterWhitelistedErrors(data.stderr)
            throw new Error(filteredErrors) if filteredErrors

            helpers.parse(data.stdout, @regex, {filePath: file})
              .filter((lintIssue) -> lintIssue.type isnt 'info')
              .map (lintIssue) ->
                [[lineStart, colStart], [lineEnd, colEnd]] = lintIssue.range

                if lineStart is lineEnd and colStart <= colEnd <= 0
                  return _.merge {}, lintIssue,
                    range: helpers.rangeFromLineNumber activeEditor, lineStart, colStart

                lintIssue

  replaceVars: (string, data, longKeyData) ->
    # Escapes required for terrible env names like PROGRAMFILES(X86): %(PROGRAMFILES\\(X86\\))
    string.replace /%(\w|\((([^()\\]|(\\(\\{2})*([()\\])))+)\))/g, (str, key, longKey) ->
      ret = if longKey then longKeyData[longKey.replace(/\\([\\()])/g, '$1')] else data[key]
      ret ? str

  getProjDir: (filePath) ->
    atom.project.relativizePath(filePath)[0]

  filterWhitelistedErrors: (output) ->
    outputLines = _.compact output.split(os.EOL)
    filteredOutputLines = _.reject outputLines, (outputLine) =>
      _.some @errorWhitelist, (errorRegex) ->
        errorRegex.test outputLine

    filteredOutputLines.join os.EOL

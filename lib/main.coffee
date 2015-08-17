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
      description: 'Command or path to executable.'
    pythonPath:
      type: 'string'
      default: ''
      description: 'Paths to be added to $PYTHONPATH.  Use %p for current project directory (no trailing /).'
    rcFile:
      type: 'string'
      default: ''
      description: 'Path to .pylintrc file.'
    messageFormat:
        type: 'string'
        default: '%i %m'
        description:
            'Format for Pylint messages where %m is the message, %i is the
            numeric mesasge ID (e.g. W0613) and %s is the human-readable
            message ID (e.g. unused-argument).'

  activate: ->
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

    @regex = '^(?<line>\\d+),(?<col>\\d+),\
               (?<type>\\w+),\
               (\\w\\d+):(?<message>.*)$'

    @errorWhitelist = [
      /^No config file found, using default configuration$/
    ]

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      grammarScopes: ['source.python']
      scope: 'file'
      lintOnFly: true
      lint: (activeEditor) =>
        file = activeEditor.getPath()
        return helpers.tempFile path.basename(file), activeEditor.getText(), (tmpFilename) =>
          projDir = @getProjDir(file)
          cwd = projDir
          pythonPath = @pythonPath.replace(/%p/g, projDir)
          env = Object.create process.env,
            PYTHONPATH:
              value: _.compact([process.env.PYTHONPATH, projDir, pythonPath]).join path.delimiter
          format = @messageFormat
          for pattern, value of {'%m': 'msg', '%i': 'msg_id', '%s': 'symbol'}
            format = format.replace(new RegExp(pattern, 'g'), "{#{value}}")
          args = [
            "--msg-template='{line},{column},{category},{msg_id}:#{format}'"
            '--reports=n'
            '--output-format=text'
          ]
          if @rcFile
            args.push "--rcfile=#{@rcFile}"
          args.push tmpFilename
          return helpers.exec(@executable, args, {env: env, cwd: cwd, stream: 'both'}).then (data) =>
            filteredErrors = @filterWhitelistedErrors(data.stderr)
            throw new Error(filteredErrors) if filteredErrors
            helpers.parse(data.stdout, @regex, {filePath: file})
              .filter((lintIssue) ->lintIssue.type isnt 'info')
              .map (lintIssue) ->
                [[lineStart, colStart], [lineEnd, colEnd]] = lintIssue.range
                if lineStart == lineEnd and colStart <= colEnd <= 0
                  return _.merge {}, lintIssue,
                    range: helpers.rangeFromLineNumber activeEditor, lineStart, colStart
                lintIssue

  getProjDir: (filePath) ->
    _.find atom.project.getPaths(), (projPath) ->
      filePath.indexOf(projPath) == 0

  filterWhitelistedErrors: (output) ->
    outputLines = _.compact output.split(os.EOL)
    filteredOutputLines = _.reject outputLines, (outputLine) =>
      _.some @errorWhitelist, (errorRegex) ->
        errorRegex.test outputLine

    filteredOutputLines.join os.EOL

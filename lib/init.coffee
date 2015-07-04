module.exports =
  config:
    executable:
      type: 'string'
      default: 'pylint'
    rcFile:
      type: 'string'
      default: ''
    messageFormat:
        type: 'string'
        default: '%m'
        description:
            'Format for Pylint messages, where %m is message, %i is the
            numeric mesasge ID (e.g. W0613) and %s is the human-readable
            message ID (e.g. unused-argument).'

  activate: ->
    console.log 'Linter-Pylint: package loaded,
                 ready to get initialized by AtomLinter.'

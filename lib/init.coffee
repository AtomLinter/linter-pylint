module.exports =
  config:
    executable:
      type: 'string'
      default: 'pylint'
    rcFile:
      type: 'string'
      default: ''

  activate: ->
    console.log 'Linter-Pylint: package loaded,
                 ready to get initialized by AtomLinter.'

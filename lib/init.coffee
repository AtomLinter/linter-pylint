module.exports =
  config:
    executable:
      type: 'string'
      default: 'pylint'
    rcFile:
      type: 'string'
      default: ''
    showCodes:
      description: "Shows the pylint code in linter messages (E1101, etc.)"
      type: 'boolean'
      default: false
    showReadableCodes:
      description: "Shows the human-readable pylint symbol in linter messages (e.g., unused-import for W0611)"
      type: 'boolean'
      default: false

  activate: ->
    console.log 'Linter-Pylint: package loaded,
                 ready to get initialized by AtomLinter.'

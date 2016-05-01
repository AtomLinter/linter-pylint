{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'
path = require 'path'
_ = require 'lodash'
os = require 'os'
tmp = require 'tmp'
fs = require 'fs'

tmp.setGracefulCleanup()

readdir = (dir) ->
  new Promise (resolve, reject) ->
    fs.readdir dir, (err, files) ->
      return reject err if err
      resolve files

stat = (file) ->
  new Promise (resolve, reject) ->
    fs.stat file, (err, stats) ->
      return reject err if err
      resolve stats

mkdir = (folder) ->
  new Promise (resolve, reject) ->
    fs.mkdir folder, 0o750, (err) ->
      return reject(err) if err
      resolve()

link = (to, linkname) ->
  new Promise (resolve, reject) ->
    fs.link to, linkname, (err) ->
      return reject(err) if err
      resolve()

unlink = (linkname) ->
  new Promise (resolve, reject) ->
    fs.unlink linkname, (err) ->
      return reject(err) if err
      resolve()

writeFile = (file, text) ->
  new Promise (resolve, reject) ->
    fs.writeFile file, text, (err) ->
      return reject(err) if err
      resolve()

findFiles = (root) -> new Promise (resolve, reject) ->
  readdir root
  .then (files) ->

    promises = []
    for f in files

      p = new Promise (resolve, reject) ->
        filepath = path.join root, f
        stat filepath
        .then (stats) ->
          resolve {'path': filepath, 'stats': stats}
        .catch (err) -> reject err

      promises.push p

    Promise.all(promises).then (files) ->
      resolve files
    .catch (err) -> reject err
  .catch (err) -> reject err

module.exports =
  config:
    executable:
      type: 'string'
      default: 'pylint'
      description: 'Command or path to executable. Use %p for current project directory (no trailing /).'
    pythonPath:
      type: 'string'
      default: ''
      description: 'Paths to be added to $PYTHONPATH. Use %p for current project directory or %f for the directory of
        the current file.'
    rcFile:
      type: 'string'
      default: ''
      description: 'Path to pylintrc file. Use %p for the current project directory or %f for the directory of the
        current file.'
    workingDirectory:
      type: 'string'
      default: '%p'
      description: 'Directory pylint is run from. Use %p for the current project directory or %f for the directory
        of the current file.'
    messageFormat:
      type: 'string'
      default: '%i %m'
      description:
        'Format for Pylint messages where %m is the message, %i is the
        numeric mesasge ID (e.g. W0613) and %s is the human-readable
        message ID (e.g. unused-argument).'

  activate: ->
    require('atom-package-deps').install('linter-pylint')
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

    @errorWhitelist = [
      /^No config file found, using default configuration$/
    ]

    @projStatus = {}

  deactivate: ->
    @subscriptions.dispose()

  getProjDir: (file) ->
    atom.project.relativizePath(file)[0] or path.dirname file

  getMessageFormat: ->
    format = @messageFormat
    for pattern, value of {'%m': 'msg', '%i': 'msg_id', '%s': 'symbol'}
      format = format.replace(new RegExp(pattern, 'g'), "{#{value}}")
    return format

  getArgs: (file, filedir, pdir) ->
    format = @getMessageFormat()
    args = [
      "--msg-template='{line},{column},{category},{msg_id}:#{format}'"
      '--reports=n'
      '--output-format=text'
    ]
    if @rcFile
      rcFile = @rcFile.replace(/%p/g, pdir).replace(/%f/g, filedir)
      args.push "--rcfile=#{rcFile}"
    args.push file
    return args

  checkFile: (file, activeEditor) ->
    origFile = file
    pdir = @getProjDir file
    from_root = path.dirname pdir

    rel_file = path.relative(from_root, file)
    rel_filedir = path.relative(from_root, path.dirname file)
    rel_pdir = path.relative(from_root, pdir)

    @projStatus[pdir]
    .then (to_root) =>
      filedir = path.join to_root.path, rel_filedir
      file = path.join to_root.path, rel_file
      pdir = path.join to_root.path, rel_pdir

      cwd = @cwd.replace(/%f/g, filedir).replace(/%p/g, pdir)
      executable = @executable.replace(/%p/g, pdir)

      env = @createEnv filedir, pdir
      args = @getArgs file, filedir, pdir
      opts = {env: env, cwd: cwd, stream: 'both'}

      return helpers.exec(executable, args, opts).then (data) =>
        filteredErrors = @filterWhitelistedErrors(data.stderr)
        throw new Error(filteredErrors) if filteredErrors
        helpers.parse(data.stdout, @regex, {filePath: origFile})
          .filter((lintIssue) -> lintIssue.type isnt 'info')
          .map (lintIssue) =>
            [[lineStart, colStart], [lineEnd, colEnd]] = lintIssue.range
            if lineStart is lineEnd and colStart <= colEnd <= 0
              return _.merge {}, lintIssue,
                range: helpers.rangeFromLineNumber activeEditor, lineStart, colStart
            lintIssue

  createEnv: (filedir, pdir) ->
    pythonPath = @pythonPath.replace(/%f/g, filedir).replace(/%p/g, pdir)
    env = Object.create process.env,
      PYTHONPATH:
        value: _.compact([process.env.PYTHONPATH, pdir, filedir,
                          pythonPath]).join path.delimiter
        enumerable: true

  provideLinter: ->
    provider =
      name: 'Pylint'
      grammarScopes: ['source.python']
      scope: 'file'
      lintOnFly: true
      lint: (activeEditor) => new Promise (resolve, reject) =>
        file = activeEditor.getPath()
        text = activeEditor.getText()
        @prepareProj file
        .then () =>
          @unlink file
        .then () =>
          @writeText file, text
        .then () =>
          @checkFile file, activeEditor
        .then (info) =>
          @unlink(file).then(=> @link file).then(-> resolve info)

  link: (file) ->
    pdir = @getProjDir file
    from_root = path.dirname pdir
    rel = path.relative(from_root, file)

    @projStatus[pdir]
    .then (to_root) ->
      link path.join(from_root, rel), path.join(to_root.path, rel)

  unlink: (file) ->
    pdir = @getProjDir file
    from_root = path.dirname pdir
    rel = path.relative(from_root, file)

    @projStatus[pdir]
    .then (to_root) ->
      unlink path.join(to_root.path, rel)


  writeText: (file, text) ->
    pdir = @getProjDir file
    from_root = path.dirname pdir
    rel = path.relative(from_root, file)

    @projStatus[pdir]
    .then (to_root) ->
      fs.writeFile path.join(to_root.path, rel), text

  prepareProj: (file) ->
    pdir = @getProjDir file

    return @projStatus[pdir] if pdir of @projStatus

    @projStatus[pdir] = new Promise (resolve, reject) =>

      @getTempDirectory 'linter-pylint_'
      .then (tempDir) =>

        new Promise (resolve, reject) =>
          @duplicateFolder pdir, tempDir.path
          .then () -> resolve tempDir
          .catch (err) -> reject err

      .then (tempDir) -> resolve tempDir
      .catch (err) -> reject err

    return @projStatus[pdir]

  getTempDirectory: (prefix) ->
    new Promise (resolve, reject) =>
      tmp.dir { prefix, unsafeCleanup: true }, (err, directory, cleanup) =>
        return reject err if err
        @subscriptions.add { dispose: -> cleanup() }
        resolve { path:directory, cleanup }

  _duplicateFolder: (from_root, to_root, folder) -> new Promise (resolve, reject) =>
    mkdir path.join to_root, folder
    .then () =>
      findFiles path.join(from_root, folder)
      .then (files) =>
        new Promise (resolve, reject) =>
          promises = []
          for file in files
            rel = path.relative(from_root, file.path)
            if file.stats.isDirectory()
              do (rel) =>
                promises.push @_duplicateFolder(from_root, to_root, rel)
            else if file.stats.isFile()
              do (rel) =>
                promises.push link(file.path, path.join(to_root, rel))
          Promise.all(promises)
          .then () -> resolve()
          .catch (err) -> reject err
      .then () ->
        resolve()
      .catch (err) ->
        reject err

  duplicateFolder: (from, to) ->
    from_root = path.dirname from
    to_root = to
    folder = path.basename from

    @_duplicateFolder from_root, to_root, folder

  filterWhitelistedErrors: (output) ->
    outputLines = _.compact output.split(os.EOL)
    filteredOutputLines = _.reject outputLines, (outputLine) =>
      _.some @errorWhitelist, (errorRegex) ->
        errorRegex.test outputLine

    filteredOutputLines.join os.EOL

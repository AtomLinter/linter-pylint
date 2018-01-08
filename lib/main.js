'use babel';

/**
 * Note that this can't be loaded lazily as `atom` doesn't export it correctly
 * for that, however as this comes from app.asar it is pre-compiled and is
 * essentially "free" as there is no expensive compilation step.
 */
// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable } from 'atom';
import path from 'path';

const lazyReq = require('lazy-req')(require);

const { delimiter, dirname } = lazyReq('path')('delimiter', 'dirname');
const { exec, generateRange } = lazyReq('atom-linter')('exec', 'generateRange');
const os = lazyReq('os');

// Some local variables
const errorWhitelist = [
  /^No config file found, using default configuration$/,
  /^Using config file /,
];

const getProjectDir = (filePath) => {
  const atomProject = atom.project.relativizePath(filePath)[0];
  if (atomProject === null) {
    // Default project to file directory if project path cannot be determined
    return dirname(filePath);
  }
  return atomProject;
};

const filterWhitelistedErrors = (stderr) => {
  // Split the input and remove blank lines
  const lines = stderr.split(os().EOL).filter(line => !!line);
  const filteredLines = lines.filter(line =>
    // Only keep the line if it is not ignored
    !errorWhitelist.some(errorRegex => errorRegex.test(line)));
  return filteredLines.join(os().EOL);
};

const fixPathString = (pathString, fileDir, projectDir) => {
  const string = pathString;
  const fRstring = string.replace(/%f/g, fileDir);
  const hRstring = fRstring.replace(/%h/g, path.basename(projectDir));
  const pRstring = hRstring.replace(/%p/g, projectDir);
  return pRstring;
};

const determineSeverity = (severity) => {
  switch (severity) {
    case 'error':
    case 'warning':
    case 'info':
      return severity;
    case 'convention':
      return 'info';
    default:
      return 'warning';
  }
};

export default {
  activate() {
    require('atom-package-deps').install('linter-pylint');

    this.subscriptions = new CompositeDisposable();

    // FIXME: Remove backwards compatibility in a future minor version
    const oldPath = atom.config.get('linter-pylint.executable');
    if (oldPath !== undefined) {
      atom.config.unset('linter-pylint.executable');
      if (oldPath !== 'pylint') {
        // If the old config wasn't set to the default migrate it over
        atom.config.set('linter-pylint.executablePath', oldPath);
      }
    }

    this.subscriptions.add(atom.config.observe('linter-pylint.executablePath', (value) => {
      this.executablePath = value;
    }));
    this.subscriptions.add(atom.config.observe('linter-pylint.rcFile', (value) => {
      this.rcFile = value;
    }));
    this.subscriptions.add(atom.config.observe('linter-pylint.messageFormat', (value) => {
      this.messageFormat = value;
    }));
    this.subscriptions.add(atom.config.observe('linter-pylint.pythonPath', (value) => {
      this.pythonPath = value;
    }));
    this.subscriptions.add(atom.config.observe('linter-pylint.workingDirectory', (value) => {
      this.workingDirectory = value.replace(delimiter, '');
    }));
    this.subscriptions.add(atom.config.observe('linter-pylint.disableTimeout', (value) => {
      this.disableTimeout = value;
    }));
  },

  deactivate() {
    this.subscriptions.dispose();
  },

  provideLinter() {
    return {
      name: 'Pylint',
      scope: 'file',
      lintsOnChange: false,
      grammarScopes: ['source.python', 'source.python.django'],
      lint: async (editor) => {
        const filePath = editor.getPath();
        const fileDir = dirname(filePath);
        const fileText = editor.getText();
        const projectDir = getProjectDir(filePath);
        const cwd = fixPathString(this.workingDirectory, fileDir, projectDir);
        const execPath = fixPathString(this.executablePath, '', projectDir);
        let format = this.messageFormat;
        const patterns = {
          '%m': 'msg',
          '%i': 'msg_id',
          '%s': 'symbol',
        };
        Object.keys(patterns).forEach((pattern) => {
          format = format.replace(new RegExp(pattern, 'g'), `{${patterns[pattern]}}`);
        });
        const env = Object.create(process.env, {
          PYTHONPATH: {
            value: [
              process.env.PYTHONPATH,
              fixPathString(this.pythonPath, fileDir, projectDir),
            ].filter(x => !!x).join(delimiter),
            enumerable: true,
          },
          LANG: { value: 'en_US.UTF-8', enumerable: true },
        });

        const args = [
          `--msg-template='{line},{column},{category},{msg_id}:${format}'`,
          '--reports=n',
          '--output-format=text',
        ];
        if (this.rcFile !== '') {
          args.push(`--rcfile=${fixPathString(this.rcFile, fileDir, projectDir)}`);
        }
        args.push(filePath);

        const execOpts = { env, cwd, stream: 'both' };
        if (this.disableTimeout) {
          execOpts.timeout = Infinity;
        }

        const data = await exec(execPath, args, execOpts);

        if (editor.getText() !== fileText) {
          // Editor text was modified since the lint was triggered, tell Linter not to update
          return null;
        }

        const filteredErrors = filterWhitelistedErrors(data.stderr);
        if (filteredErrors) {
          // pylint threw an error we aren't ignoring!
          throw new Error(filteredErrors);
        }

        const lineRegex = /(\d+),(\d+),(\w+),(\w\d+):(.*)\r?(?:\n|$)/g;
        const toReturn = [];

        let match = lineRegex.exec(data.stdout);
        while (match !== null) {
          const line = Number.parseInt(match[1], 10) - 1;
          const column = Number.parseInt(match[2], 10);
          const position = generateRange(editor, line, column);
          const message = {
            severity: determineSeverity(match[3]),
            excerpt: match[5],
            location: { file: filePath, position },
            url: `http://pylint-messages.wikidot.com/messages:${match[4]}`,
          };

          toReturn.push(message);
          match = lineRegex.exec(data.stdout);
        }

        return toReturn;
      },
    };
  },
};

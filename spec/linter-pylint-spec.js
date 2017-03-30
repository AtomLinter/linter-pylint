'use babel';

import * as path from 'path';

const goodPath = path.join(__dirname, 'files', 'good.py');
const badPath = path.join(__dirname, 'files', 'bad.py');
const emptyPath = path.join(__dirname, 'files', 'empty.py');

const lint = require('../lib/main.js').provideLinter().lint;

const wikiURLBase = 'http://pylint-messages.wikidot.com/messages:';

describe('The pylint provider for Linter', () => {
  beforeEach(() => {
    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('linter-pylint'),
        atom.packages.activatePackage('language-python').then(() =>
          atom.workspace.open(goodPath),
        ),
      ]),
    );
  });

  it('should be in the packages list', () =>
    expect(atom.packages.isPackageLoaded('linter-pylint')).toBe(true),
  );

  it('should be an active package', () =>
    expect(atom.packages.isPackageActive('linter-pylint')).toBe(true),
  );

  describe('checks bad.py and', () => {
    let editor = null;
    beforeEach(() => {
      waitsForPromise(() =>
        atom.workspace.open(badPath).then((openEditor) => {
          editor = openEditor;
        }),
      );
    });

    it('finds at least one message', () =>
      waitsForPromise(() =>
        lint(editor).then(messages => expect(messages.length).toBeGreaterThan(0)),
      ),
    );

    it('verifies that message', () =>
      waitsForPromise(() =>
        lint(editor).then((messages) => {
          expect(messages[0].severity).toBe('info');
          expect(messages[0].excerpt).toBe('C0111 Missing module docstring');
          expect(messages[0].location.file).toBe(badPath);
          expect(messages[0].location.position).toEqual([[0, 0], [0, 4]]);
          expect(messages[0].url).toBe(`${wikiURLBase}C0111`);

          expect(messages[1].severity).toBe('warning');
          expect(messages[1].excerpt).toBe('W0104 Statement seems to have no effect');
          expect(messages[1].location.file).toBe(badPath);
          expect(messages[1].location.position).toEqual([[0, 0], [0, 4]]);
          expect(messages[1].url).toBe(`${wikiURLBase}W0104`);

          expect(messages[2].severity).toBe('error');
          expect(messages[2].excerpt).toBe("E0602 Undefined variable 'asfd'");
          expect(messages[2].location.file).toBe(badPath);
          expect(messages[2].location.position).toEqual([[0, 0], [0, 4]]);
          expect(messages[2].url).toBe(`${wikiURLBase}E0602`);
        }),
      ),
    );
  });

  it('finds nothing wrong with an empty file', () => {
    waitsForPromise(() =>
      atom.workspace.open(emptyPath).then(editor =>
        lint(editor).then(messages => expect(messages.length).toBe(0)),
      ),
    );
  });

  it('finds nothing wrong with a valid file', () => {
    waitsForPromise(() =>
      atom.workspace.open(goodPath).then(editor =>
        lint(editor).then(messages => expect(messages.length).toBe(0)),
      ),
    );
  });
});

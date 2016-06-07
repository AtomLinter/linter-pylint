'use babel';

import * as path from 'path';

const goodPath = path.join(__dirname, 'files', 'good.py');
const badPath = path.join(__dirname, 'files', 'bad.py');
const emptyPath = path.join(__dirname, 'files', 'empty.py');
const lint = require('../lib/main.js').provideLinter().lint;

describe('The pylint provider for Linter', () => {
  beforeEach(() => {
    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('linter-pylint'),
        atom.packages.activatePackage('language-python').then(() =>
          atom.workspace.open(goodPath)
        ),
      ])
    );
  });

  it('should be in the packages list', () =>
    expect(atom.packages.isPackageLoaded('linter-pylint')).toBe(true)
  );

  it('should be an active package', () =>
    expect(atom.packages.isPackageActive('linter-pylint')).toBe(true)
  );

  describe('checks bad.py and', () => {
    let editor = null;
    beforeEach(() => {
      waitsForPromise(() =>
        atom.workspace.open(badPath).then(openEditor => {
          editor = openEditor;
        })
      );
    });

    it('finds at least one message', () =>
      waitsForPromise(() =>
        lint(editor).then(messages => {
          expect(messages.length).toBeGreaterThan(0);
        })
      )
    );

    it('verifies that message', () =>
      waitsForPromise(() =>
        lint(editor).then(messages => {
          expect(messages[0].type).toBeDefined();
          expect(messages[0].type).toEqual('convention');
          expect(messages[0].html).not.toBeDefined();
          expect(messages[0].text).toBeDefined();
          expect(messages[0].text).toEqual('C0111 Missing module docstring');
          expect(messages[0].filePath).toBeDefined();
          expect(messages[0].filePath).toMatch(/.+spec[\\\/]files[\\\/]bad\.py$/);
          expect(messages[0].range).toBeDefined();
          expect(messages[0].range.length).toEqual(2);
          expect(messages[0].range).toEqual([[0, 0], [0, 4]]);
        })
      )
    );
  });

  it('finds nothing wrong with an empty file', () => {
    waitsForPromise(() =>
      atom.workspace.open(emptyPath).then(editor =>
        lint(editor).then(messages => {
          expect(messages.length).toEqual(0);
        })
      )
    );
  });

  it('finds nothing wrong with a valid file', () => {
    waitsForPromise(() =>
      atom.workspace.open(goodPath).then(editor =>
        lint(editor).then(messages => {
          expect(messages.length).toEqual(0);
        })
      )
    );
  });
});

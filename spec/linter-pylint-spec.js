'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies
import { beforeEach, it, wait } from 'jasmine-fix';
import { join } from 'path';
import testLinterUI from './testLinterUI';

const goodPath = join(__dirname, 'files', 'good.py');
const badPath = join(__dirname, 'files', 'bad.py');
const emptyPath = join(__dirname, 'files', 'empty.py');

const lint = require('../lib/main.js').provideLinter().lint;

const wikiURLBase = 'http://pylint-messages.wikidot.com/messages:';
const testUI = join(__dirname, 'testLinterUI');

describe('The pylint provider for Linter', () => {
  beforeEach(async () => {
    const workspaceElement = atom.views.getView(atom.workspace);
    jasmine.attachToDOM(workspaceElement);

    // Load the test UI
    // NOTE: Non-public API!
    atom.packages.loadPackage(testUI);
    // Activate Linter and the test UI
    await atom.packages.activatePackage('linter');
    await atom.packages.activatePackage('testLinterUI');

    // Activate language-python so Atom knows what language the files are
    await atom.packages.activatePackage('language-python');

    // Activate linter-pylint now that everything is ready
    await atom.packages.activatePackage('linter-pylint');
  });

  it('should be in the packages list', () =>
    expect(atom.packages.isPackageLoaded('linter-pylint')).toBe(true),
  );

  it('should be an active package', () =>
    expect(atom.packages.isPackageActive('linter-pylint')).toBe(true),
  );

  fdescribe('checks bad.py and', () => {
    let messages;

    beforeEach(async () => {
      // Open an editor on one of the test files
      const editor = await atom.workspace.open(badPath);
      // Grab the view for the editor
      const editorView = atom.views.getView(editor);
      // Trigger a lint
      atom.commands.dispatch(editorView, 'linter:lint');
      // Spy on the UI message renderer
      spyOn(testLinterUI, 'render').andCallFake((messagePatch) => {
        messages = messagePatch.messages;
      });
      // Wait 2000 ms for the lint (pylint can be slow)
      await wait(2000);
    });

    it('verifies the messages', () => {
      expect(messages.length).toBe(3);

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
    });
  });

  describe('finds nothing wrong with an empty file', async () => {
    const editor = await atom.workspace.open(emptyPath);
    const messages = await lint(editor);
    expect(messages.length).toBe(0);
  });

  it('finds nothing wrong with a valid file', async () => {
    const editor = await atom.workspace.open(goodPath);
    const messages = await lint(editor);
    expect(messages.length).toBe(0);
  });
});

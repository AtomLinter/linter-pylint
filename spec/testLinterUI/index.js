'use babel';

/* eslint-disable no-console */

export default {
  activate() {
    console.log('testLinterUI activate()');
  },

  deactivate() {
    console.log('testLinterUI deactivate()');
  },

  render(messagePatch) {
    console.log('testLinterUI render():', messagePatch);
  },

  didBeginLinting(linter, filePath) {
    console.log('testLinterUI didBeginLinting():', linter, filePath);
  },

  didFinishLinting(linter, filePath) {
    console.log('testLinterUI didFinishLinting():', linter, filePath);
  },

  dispose() {
    console.log('testLinterUI dispose()');
  },

  provideUI() {
    console.log('testLinterUI: provideUI()');
    return {
      name: 'test-ui',
      render(messagePatch) {
        this.render(messagePatch);
      },
      didBeginLinting(linter, filePath) {
        this.didBeginLinting(linter, filePath);
      },
      didFinishLinting(linter, filePath) {
        this.didFinishLinting(linter, filePath);
      },
      dispose() {
        this.dispose();
      },
    };
  },
};

/* eslint-enable no-console */

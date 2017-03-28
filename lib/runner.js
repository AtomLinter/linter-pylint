'use babel';

/* global emit */

import { exec } from 'atom-linter';

export default async function runPylint(execPath, execArgs, opts) {
  this.async();
  const execOpts = Object.assign({ timeout: Infinity }, opts);
  let result;
  try {
    result = exec(execPath, execArgs, execOpts);
  } catch (err) {
    emit('linter-pylint:error', err);
  }
  process.on('SIGTERM', () => {
    result.kill();
    process.exit(0);
  });
  emit('linter-pylint:results', await result);
}

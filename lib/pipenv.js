'use babel';

import path from 'path';

import { promisify } from 'util';
import { stat } from 'fs';

const lazyReq = require('lazy-req')(require);

const { exec } = lazyReq('atom-linter')('exec');


let pipEnvAvailable = null;
const pipEnvProjects = {};

const checkPipEnvAvailable = async () => {
  try {
    await exec('pipenv', ['--version']);
    return true;
  } catch (e) {
    return false;
  }
};

const isPipEnvAvailable = async () => {
  if (pipEnvAvailable !== null) {
    return pipEnvAvailable;
  }
  pipEnvAvailable = await checkPipEnvAvailable();
  return pipEnvAvailable;
};

const getPipEnvProject = projectDir => pipEnvProjects[projectDir] || null;

const readPipEnvVariable = async (lambda, defaultValue = null) => {
  try {
    return await lambda();
  } catch (error) {
    return defaultValue;
  }
};

const loadProjectConfig = async (projectDir) => {
  const existingConfig = getPipEnvProject(projectDir);
  if (existingConfig) {
    return existingConfig;
  }

  const config = {
    pylintExecutable: null,
    pythonPath: [],
    pipEnvHome: null,
  };

  if (!(await isPipEnvAvailable())) {
    pipEnvProjects[projectDir] = config;
    return config;
  }

  config.pipEnvHome = await readPipEnvVariable(async () => exec('pipenv', ['--venv'], {
    cwd: projectDir,
  }));
  config.pythonPath = await readPipEnvVariable(async () => {
    const pipEnvArgs = [
      'run',
      'python',
      '-c',
      'import sys; import json; print(json.dumps(sys.path))',
    ];
    return JSON.parse(await exec('pipenv', pipEnvArgs, {
      cwd: projectDir,
    }));
  }, []);
  config.pylintExecutable = config.pipEnvHome
    ? await readPipEnvVariable(async () => {
      const linterPath = path.join(config.pipEnvHome, 'bin', 'pylint');
      const linterStat = await promisify(stat)(linterPath);
      return linterStat ? path : null;
    })
    : null;
  pipEnvProjects[projectDir] = config;
  return config;
};

module.exports = {
  loadProjectConfig,
  getPipEnvProject,
};

#!/usr/bin/env node

import fs from 'node:fs';

const version = process.argv[2] || '';
if (!/^\d+\.\d+\.\d+$/.test(version)) {
  throw new Error(`Invalid mongosh release version: ${version || '(empty)'}`);
}

const cliPackagePath = 'packages/cli-repl/package.json';
const cliPackage = JSON.parse(fs.readFileSync(cliPackagePath, 'utf8'));
cliPackage.version = version;
fs.writeFileSync(cliPackagePath, `${JSON.stringify(cliPackage, null, 2)}\n`);

const shellVersionPath = 'packages/shell-api/src/mongosh-version.ts';
const shellVersion = fs.readFileSync(shellVersionPath, 'utf8');
if (!/MONGOSH_VERSION = '[^']+'/.test(shellVersion)) {
  throw new Error(`Could not find MONGOSH_VERSION in ${shellVersionPath}`);
}
fs.writeFileSync(shellVersionPath, shellVersion.replace(
  /MONGOSH_VERSION = '[^']+'/, `MONGOSH_VERSION = '${version}'`,
));

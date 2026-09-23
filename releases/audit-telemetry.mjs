#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const ignoredDirectories = new Set(['node_modules', 'lib', 'dist', 'test', 'tests',
  '__tests__', 'fixtures', '__fixtures__', '.git', '.sbom', 'coverage']);
export function sourceSnapshot(root) {
  const files = {};
  function visit(relative) {
    for (const entry of readdirSync(join(root, relative), { withFileTypes: true })) {
      const name = `${relative}/${entry.name}`;
      if (entry.isSymbolicLink()) throw new Error(`Unreviewed source symlink: ${name}`);
      if (entry.isDirectory()) {
        if (!ignoredDirectories.has(entry.name)) visit(name);
      } else if (/\.(?:[cm]?js|jsx|tsx?|json|wasm|node)$/.test(entry.name) &&
                 !/\.(?:spec|test)\./.test(entry.name)) {
        files[name] = hash(readFileSync(join(root, name)));
      }
    }
  }
  for (const dir of ['packages', 'scripts', 'config', 'configs']) {
    if (existsSync(join(root, dir))) visit(dir);
  }
  for (const file of ['package.json', 'package-lock.json', '.npmrc']) {
    if (existsSync(join(root, file))) files[file] = hash(readFileSync(join(root, file)));
  }
  return Object.fromEntries(Object.entries(files).sort(([a], [b]) => a.localeCompare(b, 'en')));
}
function hash(bytes) { return createHash('sha256').update(bytes).digest('hex'); }
export function auditSource(root, reviewed) {
  const actual = sourceSnapshot(root);
  const changed = [...new Set([...Object.keys(reviewed.files), ...Object.keys(actual)])]
    .filter(file => reviewed.files[file] !== actual[file]);
  if (changed.length) throw new Error(
    `Telemetry audit required: unreviewed source/dependency changes:\n${changed.join('\n')}\n` +
    'Review upstream changes and telemetry removal before updating the audit manifest.');
  return Object.keys(actual).length;
}

// These signatures belong to the removed implementations, not compatibility APIs.
// Scan the actual production artifact, including bundled dependencies.
export function auditBundle(file) {
  const bundle = readFileSync(file, 'utf8');
  if (!bundle.trim()) throw new Error('Missing or empty mongosh bundle: ' + file);
  const forbidden = ['mongosh-telemetry.mongodb.com', 'Sending telemetry event',
    'Persisted telemetry throttle state', 'commands_repl', 'sequence_truncated',
    'KNOWN_AGENT_ENV_VARS', 'getAiAgent', 'TelemetryClient', 'ThrottledAnalytics',
    '@mongodb-js/native-machine-id', '@mongodb-js/device-id', '@mongodb-js/get-os-info',
    'MONGOSH_TELEMETRY_ENDPOINT', 'emitApiCallTelemetry'];
  const found = forbidden.filter(value => bundle.includes(value));
  if (/["'`]mge=/.test(bundle)) found.push('telemetry Cookie payload');
  if (found.length) throw new Error(`Telemetry implementation remains in bundle: ${found.join(', ')}`);
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    if (process.argv[2] === '--bundle') {
      auditBundle(process.argv[3]);
      console.log('Bundled telemetry implementation checks passed');
    } else {
      const manifest = JSON.parse(readFileSync(new URL('./telemetry-audit.json', import.meta.url)));
      const count = auditSource(resolve(process.argv[2] || '.'), manifest);
      console.log(`Telemetry audit passed: ${count} reviewed source/dependency files`);
    }
  } catch (error) { console.error('::error::Telemetry audit failed: ' + error.message); process.exitCode = 1; }
}

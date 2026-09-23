import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, readFileSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { sourceSnapshot, auditSource, auditBundle } from '../releases/audit-telemetry.mjs';

test('source audit rejects new, changed, deleted and dependency code, even without telemetry keywords', () => {
  const root = mkdtempSync(join(tmpdir(), 'mongosh-audit-'));
  try {
    mkdirSync(join(root, 'packages/example/src'), { recursive: true });
    const file = join(root, 'packages/example/src/index.ts');
    writeFileSync(file, 'export const value = 1;');
    writeFileSync(join(root, 'package-lock.json'), '{"lockfileVersion":3}');
    const reviewed = { files: sourceSnapshot(root) };
    assert.equal(auditSource(root, reviewed), 2);
    writeFileSync(file, 'export const value = 2;');
    assert.throws(() => auditSource(root, reviewed), /index.ts/);
    writeFileSync(file, 'export const value = 1;');
    const extra = join(root, 'packages/example/src/new-provider.js');
    writeFileSync(extra, 'fetch("https://example.invalid");');
    assert.throws(() => auditSource(root, reviewed), /new-provider.js/);
    rmSync(extra);
    rmSync(file);
    assert.throws(() => auditSource(root, reviewed), /index.ts/);
    writeFileSync(file, 'export const value = 1;');
    writeFileSync(join(root, 'package-lock.json'), '{"lockfileVersion":4}');
    assert.throws(() => auditSource(root, reviewed), /package-lock.json/);
    symlinkSync(file, extra);
    assert.throws(() => auditSource(root, reviewed), /Unreviewed source symlink/);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('bundle audit rejects the removed client, local collection and fingerprint code', () => {
  const root = mkdtempSync(join(tmpdir(), 'mongosh-bundle-audit-'));
  try {
    const file = join(root, 'mongosh.js');
    writeFileSync(file, 'console.log("Telemetry has been removed from this build");');
    assert.doesNotThrow(() => auditBundle(file));
    writeFileSync(file, '');
    assert.throws(() => auditBundle(file), /empty mongosh bundle/);
    for (const value of ['TelemetryClient', 'commands_repl', 'getAiAgent',
      '"mge=', '@mongodb-js/native-machine-id', 'Sending telemetry event']) {
      writeFileSync(file, `/* bundled dependency */ ${value}`);
      assert.throws(() => auditBundle(file), /Telemetry implementation remains/);
    }
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('both source preparation and bundle building enforce review, and artifact scan precedes packaging', () => {
  const prepare = readFileSync(new URL('../releases/prepare-source.sh', import.meta.url), 'utf8');
  const build = readFileSync(new URL('../releases/build-bundle.sh', import.meta.url), 'utf8');
  assert.match(prepare, /node "\$patches\/releases\/audit-telemetry.mjs" \./);
  assert.ok(build.indexOf('/audit-telemetry.mjs" .') < build.indexOf('npm ci'));
  assert.ok(build.indexOf('/audit-telemetry.mjs" --bundle') < build.indexOf('cp packages/cli-repl/dist/mongosh.js'));
});


test('packaging rejects an old telemetry bundle before downloading a runtime', () => {
  const root = mkdtempSync(join(tmpdir(), 'mongosh-old-bundle-'));
  try {
    const bundle = join(root, 'mongosh.js');
    writeFileSync(bundle, 'class TelemetryClient {}');
    const result = spawnSync('bash', [fileURLToPath(new URL('../releases/package-target.sh', import.meta.url)), 'amd64', bundle], {
      cwd: root, encoding: 'utf8', timeout: 5000,
      env: { ...process.env, NODE_PATCHES_REPO: 'invalid/invalid' },
    });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /::error::Telemetry audit failed:/);
    assert.match(result.stderr, /Telemetry implementation remains/);
    assert.doesNotMatch(result.stderr, /curl/);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

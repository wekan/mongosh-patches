import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';

const root = fileURLToPath(new URL('../', import.meta.url));
const patch = join(root, 'dist/all/remove-telemetry.patch');
const fixture = join(root, 'tests/fixtures/upstream-1270eeb5425c');
function withSource(run) {
  const cwd = mkdtempSync(join(tmpdir(), 'mongosh-patch-'));
  try {
    cpSync(fixture, cwd, { recursive: true });
    // Isolate git apply from any enclosing repository's prefix or ignore rules.
    assert.equal(spawnSync('git', ['init', '-q', cwd]).status, 0);
    return run(cwd);
  } finally { rmSync(cwd, { recursive: true, force: true }); }
}
function apply(cwd) {
  return spawnSync('git', ['apply', '--verbose', patch], { cwd, encoding: 'utf8' });
}
function source(cwd, name) {
  return readFileSync(join(cwd, 'packages/cli-repl/src', name), 'utf8');
}

test('verified telemetry patch applies to the exact source from the failed build', async () => {
  const expected = readFileSync(patch.replace('.patch', '.sha256sum'), 'utf8').split(/\s/)[0];
  assert.equal(createHash('sha256').update(readFileSync(patch)).digest('hex'), expected);
  await withSource(cwd => {
    const result = apply(cwd);
    assert.equal(result.status, 0, result.stderr);
    const analytics = source(cwd, 'setup-analytics.ts');
    // Execute the patched function with a stand-in for the upstream no-op sink.
    // Throwing parameter getters ensure no endpoint, fetch, or device ID is read.
    class ToggleableAnalytics {}
    const code = stripTypeScriptTypes(analytics)
      .replace("import { ToggleableAnalytics } from '@mongosh/logging';", '')
      .replace('export async function', 'async function');
    const resolve = runInNewContext(`${code}\nresolveToggleableAnalytics`, { ToggleableAnalytics });
    const params = new Proxy({}, { get() { throw new Error('Telemetry input accessed'); } });
    return resolve(params).then(result => {
      assert.ok(result.analytics instanceof ToggleableAnalytics);
      assert.equal(result.telemetryEndpoint, '');
    });
  });
});

test('all patch sections preserve removal and writable-home behavior', () => {
  withSource(cwd => {
    assert.equal(apply(cwd).status, 0);
    assert.doesNotMatch(source(cwd, 'setup-analytics.ts'), /new (?:TelemetryClient|ThrottledAnalytics)\b/);
    const device = source(cwd, 'device-id.ts');
    assert.doesNotMatch(device, /native-machine-id|from '@mongodb-js\/device-id'/);
    assert.match(device, /return 'unknown';/);
    assert.match(source(cwd, 'constants.ts'), /No usage data is collected or sent by this build/);
    assert.doesNotMatch(source(cwd, 'constants.ts'), /i18n\.__\('cli-repl.cli-repl.telemetry'\)/);
    assert.match(source(cwd, 'config-directory.ts'), /path.join\(resolveWritableHomeBase\(\), '.mongodb', 'mongosh'\)/);
  });
});

test('unexpected upstream telemetry changes fail closed without partial patching', () => {
  withSource(cwd => {
    const file = join(cwd, 'packages/cli-repl/src/setup-analytics.ts');
    writeFileSync(file, source(cwd, 'setup-analytics.ts').replace('new TelemetryClient(telemetryEndpoint, fetch)', 'new DifferentTelemetryClient(telemetryEndpoint, fetch)'));
    const original = source(cwd, 'config-directory.ts');
    assert.notEqual(apply(cwd).status, 0);
    assert.equal(source(cwd, 'config-directory.ts'), original);
    assert.match(source(cwd, 'setup-analytics.ts'), /new DifferentTelemetryClient/);
  });
});

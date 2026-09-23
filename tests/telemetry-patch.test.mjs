import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cpSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import { EventEmitter } from 'node:events';
import { gunzipSync } from 'node:zlib';

const root = fileURLToPath(new URL('../', import.meta.url));
const patch = join(root, 'dist/all/remove-telemetry.patch');
const fixture = join(root, 'tests/fixtures/upstream-1270eeb5425c');
async function withSource(run) {
  const cwd = mkdtempSync(join(tmpdir(), 'mongosh-patch-'));
  try {
    cpSync(fixture, cwd, { recursive: true });
    writeFileSync(join(cwd, 'package-lock.json'), gunzipSync(readFileSync(join(cwd, 'package-lock.json.gz'))));
    // Isolate git apply from any enclosing repository's prefix or ignore rules.
    assert.equal(spawnSync('git', ['init', '-q', cwd]).status, 0);
    return await run(cwd);
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
    const helpers = stripTypeScriptTypes(readFileSync(join(cwd, 'packages/logging/src/analytics-helpers.ts'), 'utf8')).replaceAll('export ', '');
    const ToggleableAnalytics = runInNewContext(`${helpers}\nToggleableAnalytics`);
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

test('all patch sections preserve removal and writable-home behavior', async () => {
  await withSource(cwd => {
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

test('unexpected upstream telemetry changes fail closed without partial patching', async () => {
  await withSource(cwd => {
    const file = join(cwd, 'packages/cli-repl/src/setup-analytics.ts');
    writeFileSync(file, source(cwd, 'setup-analytics.ts').replace('new TelemetryClient(telemetryEndpoint, fetch)', 'new DifferentTelemetryClient(telemetryEndpoint, fetch)'));
    const original = source(cwd, 'config-directory.ts');
    assert.notEqual(apply(cwd).status, 0);
    assert.equal(source(cwd, 'config-directory.ts'), original);
    assert.match(source(cwd, 'setup-analytics.ts'), /new DifferentTelemetryClient/);
  });
});


test('patched sinks retain no events, targets or disk state, even after enable()', async () => {
  await withSource(async cwd => {
    assert.equal(apply(cwd).status, 0);
    const text = readFileSync(join(cwd, 'packages/logging/src/analytics-helpers.ts'), 'utf8');
    const code = stripTypeScriptTypes(text).replaceAll('export ', '');
    const Sink = runInNewContext(`${code}\nToggleableAnalytics`);
    const forbidden = new Proxy({}, { get() { throw new Error('Telemetry data accessed'); } });
    const sink = new Sink(forbidden);
    for (let n = 0; n < 100; n++) {
      sink.track(forbidden);
      sink.enable();
      sink.pause();
      sink.disable();
    }
    await sink.flush();
    assert.deepEqual(Object.keys(sink), []);
    for (const file of ['telemetry-client.ts', 'telemetry-events.ts']) {
      assert.equal(existsSync(join(cwd, 'packages/logging/src', file)), false);
    }
    const lock = readFileSync(join(cwd, 'package-lock.json'), 'utf8');
    assert.doesNotMatch(lock, /@mongodb-js\/(?:native-machine-id|device-id|get-os-info)/);
  });
});

test('local diagnostics work without registering session or command collectors', async () => {
  await withSource(async cwd => {
    assert.equal(apply(cwd).status, 0);
    let code = stripTypeScriptTypes(readFileSync(join(cwd, 'packages/logging/src/logging-and-telemetry.ts'), 'utf8'));
    code = code.replace(/import[\s\S]*?from ['"][^'"]+['"];\s*/g, '').replaceAll('export ', '');
    const entries = [];
    class MongoLogWriter {
      info(...args) { entries.push(args); }
      error(...args) { entries.push(args); }
      async flush() {}
    }
    const setup = runInNewContext(`${code}\nsetupLoggingAndTelemetry`, {
      MongoLogWriter, Writable: class {}, mongoLogId: n => n,
      hookLogger() {}, redact: x => x, redactConnectionString: x => x,
      shouldRedactCommand: () => false,
    });
    const bus = new EventEmitter();
    const props = new Proxy({ bus }, { get(target, key) {
      if (key !== 'bus') throw new Error(`Telemetry parameter read: ${String(key)}`);
      return target.bus;
    } });
    const logger = setup(props);
    logger.attachLogger(new MongoLogWriter());
    for (const event of ['mongosh:api-call', 'mongosh:start-session',
      'mongosh:evaluate-started', 'mongosh:evaluate-finished']) {
      assert.equal(bus.listenerCount(event), 0, event);
      bus.emit(event, { class: 'Database', method: 'find' });
    }
    bus.emit('mongosh:error', new Error('diagnostic marker'), 'test');
    bus.emit('mongosh:connect', { uri: 'mongodb://localhost', is_atlas: false });
    await logger.flush();
    assert.ok(entries.some(args => args.includes('Error: diagnostic marker')));
    assert.ok(entries.some(args => args.includes('Connecting to server')));
    assert.doesNotMatch(JSON.stringify(entries), /Sending telemetry|Identify|Session Ended|commands_repl/);
    assert.equal('busEventState' in logger, false);
    assert.equal('analytics' in logger, false);
  });
});

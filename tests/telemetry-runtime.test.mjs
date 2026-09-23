import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const bundle = process.env.MONGOSH_TEST_BUNDLE;
const guard = fileURLToPath(new URL('./fixtures/telemetry-network-guard.cjs', import.meta.url));
test('built CLI cannot re-enable telemetry or contact upstream in eval and REPL sessions', { skip: !bundle }, () => {
  const root = mkdtempSync(join(tmpdir(), 'mongosh-runtime-'));
  try {
    const home = join(root, 'home');
    const storage = join(home, '.mongodb/mongosh');
    mkdirSync(storage, { recursive: true });
    const endpoint = 'https://telemetry-test.invalid/events';
    // Snippet index downloads are a separate feature, not usage telemetry.
    writeFileSync(join(storage, 'config'), JSON.stringify({ enableTelemetry: true, telemetryEndpoint: endpoint, snippetIndexSourceURLs: '' }));
    const windowsStorage = join(home, 'mongodb/mongosh');
    mkdirSync(windowsStorage, { recursive: true });
    writeFileSync(join(windowsStorage, 'config'), readFileSync(join(storage, 'config')));
    const globalConfig = join(root, 'global.conf');
    writeFileSync(globalConfig, JSON.stringify({ forceDisableTelemetry: false, enableTelemetry: true, telemetryEndpoint: endpoint }));
    const networkLog = join(root, 'network.log');
    const env = { ...process.env, MONGOSH_TEST_HOME: home,
      APPDATA: home, LOCALAPPDATA: home,
      MONGOSH_TEST_NETWORK_LOG: networkLog,
      MONGOSH_GLOBAL_CONFIG_FILE_FOR_TESTING: globalConfig,
      MONGOSH_TELEMETRY_ENDPOINT: endpoint, AI_AGENT: 'telemetry-test-agent',
      CI: '', IS_CI: '' };
    const commands = [
      "print('ENABLED=' + config.get('enableTelemetry'))",
      "print('ENDPOINT=' + JSON.stringify(config.get('telemetryEndpoint')))",
      'print(enableTelemetry())', 'print(disableTelemetry())',
      "try { config.set('enableTelemetry', true); throw new Error('accepted telemetry'); } catch (e) { if (!String(e).includes('Telemetry has been removed')) throw e; }",
      "try { config.set('telemetryEndpoint', 'https://telemetry-test.invalid/new'); throw new Error('accepted endpoint'); } catch (e) { if (!String(e).includes('Telemetry has been removed')) throw e; }",
      "print('RESULT=' + (6 * 7))",
    ];
    for (const interactive of [false, true]) {
      const args = ['--require', guard, resolve(bundle), '--nodb'];
      if (!interactive) args.push('--quiet', '--eval', commands.join('; '));
      const result = spawnSync(process.execPath, args, {
        env, encoding: 'utf8', timeout: 30000,
        input: interactive ? commands.join('\n') + '\nexit()\n' : undefined,
      });
      assert.equal(result.status, 0, result.stderr + result.stdout);
      assert.match(result.stdout, /ENABLED=false/);
      assert.match(result.stdout, /ENDPOINT=""/);
      assert.match(result.stdout, /Telemetry has been removed from this build/);
      assert.match(result.stdout, /RESULT=42/);
      assert.doesNotMatch(result.stdout, /Telemetry is now enabled/);
    }
    assert.equal(existsSync(networkLog), false, existsSync(networkLog) ? readFileSync(networkLog, 'utf8') : '');
    function checkFiles(dir) {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const file = join(dir, entry.name);
        if (entry.isDirectory()) checkFiles(file);
        else {
          assert.doesNotMatch(entry.name, /^am-.*\.json(?:\.lock)?$/);
          if (entry.name.endsWith('_log')) assert.doesNotMatch(readFileSync(file, 'utf8'),
            /Sending telemetry event|Persisted telemetry|commands_repl|sequence_truncated|ai_agent/);
        }
      }
    }
    checkFiles(home);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

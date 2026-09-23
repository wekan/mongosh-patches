// Loaded before mongosh: record even a caught/ignored outbound request attempt.
const fs = require('node:fs');
const os = require('node:os');
const { syncBuiltinESMExports } = require('node:module');
if (!process.env.MONGOSH_TEST_HOME || !process.env.MONGOSH_TEST_NETWORK_LOG) {
  throw new Error('Isolated telemetry smoke-test paths are required');
}
os.homedir = () => process.env.MONGOSH_TEST_HOME;
function blocked(kind) {
  return function (url) {
    fs.appendFileSync(process.env.MONGOSH_TEST_NETWORK_LOG, `${kind}: ${typeof url === 'string' ? url : url?.hostname || url?.host || ''}\n${new Error().stack}\n`);
    throw new Error(`Unexpected outbound request: ${kind}`);
  };
}
for (const name of ['http', 'https']) {
  const mod = require(`node:${name}`);
  mod.request = blocked(`${name}.request`);
  mod.get = blocked(`${name}.get`);
}
const net = require('node:net');
net.connect = blocked('net.connect');
net.createConnection = blocked('net.createConnection');
net.Socket.prototype.connect = blocked('Socket.connect');
require('node:tls').connect = blocked('tls.connect');
const dns = require('node:dns');
dns.lookup = blocked('dns.lookup');
dns.resolve = blocked('dns.resolve');
globalThis.fetch = blocked('fetch');
syncBuiltinESMExports();

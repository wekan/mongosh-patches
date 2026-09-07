#!/usr/bin/env node
// Intersect the target registry with complete runtime/checksum pairs from ONE
// Node release. Missing mongosh packages remain eligible on a later rerun.
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
export const runtimes = {
  amd64: 'node-x64', arm64: 'node-arm64', armhf: 'node-armhf',
  armv6: 'node-armv6', armv7: 'node-armv7', i386: 'node-i386',
  ppc64le: 'node-ppc64le', s390x: 'node-s390x', riscv64: 'node-riscv64',
  loong64: 'node-loong64', win64: 'node-win64.exe',
  'win-arm64': 'node-win-arm64.exe', win32: 'node-win32.exe',
  'mac-amd64': 'node-mac-x64', 'mac-arm64': 'node-mac-arm64',
  'freebsd-x64': 'node-freebsd-x64',
};
export function planTargets(release, existing) {
  if (!release || !/^v\d+\.\d+\.\d+$/.test(release.tag_name) ||
      release.draft === true || release.prerelease === true ||
      !Array.isArray(release.assets)) throw new Error('Expected a published stable Node release with assets');
  const assets = new Set(release.assets.map(a => a.name));
  const targets = [], blocked = [];
  for (const [target, runtime] of Object.entries(runtimes)) {
    const archive = `mongosh-${target}.${target.startsWith('win') ? 'zip' : 'tgz'}`;
    if (existing?.has(archive) && existing.has(`${archive}.sha256sum`)) continue;
    const checksum = `${runtime.replace(/\.exe$/, '')}.sha256sum`;
    const missing = [runtime, checksum].filter(name => !assets.has(name));
    if (missing.length) blocked.push({ target, missing });
    else targets.push(target);
  }
  return { version: release.tag_name, targets, blocked };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const release = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const existing = process.argv[3] ? new Set(fs.readFileSync(process.argv[3], 'utf8').split(/\r?\n/)) : undefined;
    const plan = planTargets(release, existing);
    for (const { target, missing } of plan.blocked) console.error(`Blocked ${target}: ${plan.version} has no ${missing.join(', ')}`);
    const output = `targets=${JSON.stringify(plan.targets)}\ncount=${plan.targets.length}\nnode-version=${plan.version}\n`;
    if (process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT, output);
    if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,
      `### Node runtime availability (${plan.version})\n\nReady packages: ${plan.targets.join(', ') || 'none'}.\n\n` +
      plan.blocked.map(b => `- **Blocked ${b.target}:** missing ${b.missing.join(', ')}; rerun after node-patches publishes these assets.\n`).join(''));
    console.log(JSON.stringify(plan));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { planTargets, runtimes } from '../releases/plan-targets.mjs';
const assets = Object.values(runtimes).flatMap(name => [{name}, {name: `${name.replace(/\.exe$/, '')}.sha256sum`}]);
const release = {tag_name:'v24.20.0', assets};
test('all sixteen complete runtime pairs remain registered', () => {
  const plan = planTargets(release);
  assert.equal(plan.targets.length, 16);
  assert.deepEqual(plan.blocked, []);
});
test('logged release omissions block only Windows ARM64 and FreeBSD', () => {
  const missing = assets.filter(a => !/win-arm64|freebsd/.test(a.name));
  const plan = planTargets({...release, assets:missing});
  assert.equal(plan.targets.length, 14);
  assert.deepEqual(plan.blocked.map(b => b.target), ['win-arm64','freebsd-x64']);
  assert.deepEqual(plan.blocked[0].missing, ['node-win-arm64.exe','node-win-arm64.sha256sum']);
});
test('a runtime without its published checksum never enters the matrix', () => {
  const plan = planTargets({...release, assets:assets.filter(a => a.name!=='node-win64.sha256sum')});
  assert(!plan.targets.includes('win64'));
  assert.deepEqual(plan.blocked[0].missing,['node-win64.sha256sum']);
});
test('missing-only waits for runtime availability and later repairs incomplete archives', () => {
  const existing = new Set(Object.keys(runtimes).filter(t => t!=='win-arm64').flatMap(t => {
    const name=`mongosh-${t}.${t.startsWith('win')?'zip':'tgz'}`;return [name,`${name}.sha256sum`];
  }));
  existing.delete('mongosh-arm64.tgz.sha256sum');
  const unavailable = {...release,assets:assets.filter(a => !a.name.includes('win-arm64'))};
  assert.deepEqual(planTargets(unavailable,existing).targets,['arm64']);
  assert.deepEqual(planTargets(release,existing).targets,['arm64','win-arm64']);
  existing.add('mongosh-arm64.tgz.sha256sum');
  assert.deepEqual(planTargets(unavailable,existing).targets,[]);
});
test('malformed or unpublished release metadata fails rather than claiming success', () => {
  for(const value of [null,{}, {...release,assets:null}, {...release,draft:true}, {...release,prerelease:true}]) assert.throws(()=>planTargets(value));
});

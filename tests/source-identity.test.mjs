import { test } from 'node:test';
import assert from 'node:assert/strict';
import { commitReference, sourceIdentity } from '../releases/resolve-source.mjs';
const sha='79267331504d0e064d30ea29046b4204de720dae';
test('newest main resolves to one immutable full commit and matching release',()=>{
 assert.equal(commitReference(),'main');
 assert.deepEqual(sourceIdentity({sha}),{commit:sha,release:'main-79267331504d'});
});
test('repairing an existing main release keeps its original commit',()=>{
 assert.equal(commitReference('main-79267331504d'),'79267331504d');
 assert.deepEqual(sourceIdentity({sha},'main-79267331504d'),sourceIdentity({sha}));
 assert.deepEqual(sourceIdentity({sha},sha),sourceIdentity({sha}));
 assert.throws(()=>sourceIdentity({sha:'f'.repeat(40)},'main-79267331504d'));
});
test('malformed refs and API responses fail closed',()=>{
 for(const value of ['v2.10.0','feature','main-123','main-XYZ123456789','$(echo x)','main\nOTHER=1','--upload-pack=x']) assert.throws(()=>commitReference(value));
 for(const value of [null,{}, {sha:'abc'}, {sha:'a'.repeat(40)+'\n'}]) assert.throws(()=>sourceIdentity(value));
});

#!/usr/bin/env node
import { pathToFileURL } from 'node:url';
export function commitReference(input = '') {
  if (input === '' || input === 'main') return 'main';
  if (/^main-[0-9a-f]{12}$/.test(input)) return input.slice(5);
  if (/^[0-9a-f]{40}$/.test(input)) return input;
  throw new Error('Source must be main, a full commit SHA, or main- followed by 12 lowercase hexadecimal characters');
}
export function sourceIdentity(document, requested = '') {
  const reference = commitReference(requested);
  if (!document || !/^[0-9a-f]{40}$/.test(document.sha)) throw new Error('Upstream API did not return a full commit SHA');
  if (reference !== 'main' && !document.sha.startsWith(reference)) throw new Error('Resolved commit does not match requested source');
  return {commit:document.sha, release:`main-${document.sha.slice(0,12)}`};
}
export async function resolveSource(input = '') {
  const ref = commitReference(input);
  const headers = {'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'};
  if (process.env.GH_TOKEN) headers.Authorization = `Bearer ${process.env.GH_TOKEN}`;
  const response = await fetch(`https://api.github.com/repos/mongodb-js/mongosh/commits/${ref}`, {headers, signal:AbortSignal.timeout(30000)});
  if (!response.ok) throw new Error(`Upstream commit lookup failed: HTTP ${response.status}`);
  return sourceIdentity(await response.json(), input);
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try { console.log(JSON.stringify(await resolveSource(process.argv[2] || ''))); }
  catch(error) { console.error(error.message); process.exitCode=1; }
}

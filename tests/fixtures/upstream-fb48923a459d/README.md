# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`fb48923a459d725b266758d8184b9a0c15525a9f`, the source in the failed build
where `mongodb-redact` and `mongodb-build-info` became the scoped
`@mongodb-js/mongodb-redact` and `@mongodb-js/mongodb-build-info` - the redact
package now sits between the removed `get-os-info` and `native-machine-id` in
the manifest, and the build-info package next to `get-os-info` in the
lockfile, moving the context of both hunks. `logging-and-telemetry.ts` and
`shell-instance-state.ts` changed there too, so they are in the overlay.
`package-lock.json.gz` is the unchanged upstream lockfile compressed with gzip
(timestamp zero). Overlay on upstream-1270eeb5425c and upstream-87266a2d7ed9
for patch regression tests; the other patched files are unchanged and the
upstream license is in the base fixture.

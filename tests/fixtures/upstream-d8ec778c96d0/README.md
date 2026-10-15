# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`d8ec778c96d0f616d9f9406a73ccf8bbbb1286dd`, the source in the failed build
where `@mongosh/*` dependency bumps (arg-parser 5.6.1, autocomplete and editor
5.9.3) moved the context of the manifest and lockfile hunks.
`package-lock.json.gz` is the unchanged upstream lockfile compressed with gzip
(timestamp zero). Overlay on upstream-1270eeb5425c and upstream-87266a2d7ed9
for patch regression tests; the other patched files are unchanged and the
upstream license is in the base fixture.

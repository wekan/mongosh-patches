# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`291267b46fe0ef48a2a8835b761dddf023146a3b`, the source in the failed build
where `@mongosh/*` dependency bumps (cli-repl 2.13.0) moved the context of the
manifest and lockfile hunks. `package-lock.json.gz` is the unchanged upstream
lockfile compressed with gzip (timestamp zero). Overlay on
upstream-1270eeb5425c and upstream-87266a2d7ed9 for patch regression tests;
the other patched files are unchanged and the upstream license is in the base
fixture.

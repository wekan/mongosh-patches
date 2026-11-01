# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`a49b3fc93e8626a9b8510d907491ff9520b40a98`, the source in the failed build
where upstream's auto-generated version bumps (`@mongosh/autocomplete` 5.9.5
to 5.9.7 among them) moved the context of the manifest and lockfile hunks; the
lines the patch removes did not change. `cli-repl.ts`,
`logging-and-telemetry.ts` and `shell-instance-state.ts` are as at
`fb48923a459d`, unchanged in a49b3fc. `package-lock.json.gz` is the unchanged
upstream lockfile compressed with gzip (timestamp zero). Overlay on
upstream-1270eeb5425c and upstream-87266a2d7ed9 for patch regression tests;
the other patched files are unchanged and the upstream license is in the base
fixture.

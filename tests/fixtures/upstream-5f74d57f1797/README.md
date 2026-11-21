# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`5f74d57f179767b194d97f5cba872e70db703c54`, the source in the failed build
where upstream's release of `@mongosh/cli-repl` 2.14.3, with
`@mongosh/autocomplete` and `@mongosh/editor` 5.9.12, in
`packages/cli-repl/package.json` and the lockfile moved the context of the
manifest and lockfile hunks; the lines the patch removes did not change.
`cli-repl.ts` is unchanged since `88b5999946ff`, with its SIGINT fix;
`logging-and-telemetry.ts` and `shell-instance-state.ts` are unchanged since
`a49b3fc93e86`. `package-lock.json.gz` is the unchanged upstream lockfile
compressed with gzip (timestamp zero). Overlay on upstream-1270eeb5425c and
upstream-87266a2d7ed9 for patch regression tests; the other patched files are
unchanged and the upstream license is in the base fixture.

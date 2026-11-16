# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`d9a50bfea8ef40ddf1da26d37a9f37303eb63c3e`, the source in the failed build
where upstream's move to the scoped
`@mongodb-js/macos-export-certificate-and-key` in
`packages/cli-repl/package.json` and the lockfile moved the context of the
manifest and lockfile hunks; the lines the patch removes did not change.
`cli-repl.ts` is unchanged since `88b5999946ff`, with its SIGINT fix;
`logging-and-telemetry.ts` and `shell-instance-state.ts` are unchanged since
`a49b3fc93e86`. `package-lock.json.gz` is the unchanged upstream lockfile
compressed with gzip (timestamp zero). Overlay on upstream-1270eeb5425c and
upstream-87266a2d7ed9 for patch regression tests; the other patched files are
unchanged and the upstream license is in the base fixture.

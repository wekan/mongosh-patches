# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`88b5999946ff273ee82fb0d2c17225b6480b5029`, the source in the failed build
where upstream's dependency updates in `packages/cli-repl/package.json`
(`@mongodb-js/devtools-proxy-support` ^0.7.29, `mongodb-log-writer` ^3.0.4, the
acorn packages, without `is-recoverable-error`) and the lockfile moved the
context of the manifest and lockfile hunks; the lines the patch removes did not
change. `cli-repl.ts` is 88b5999's, with its SIGINT fix;
`logging-and-telemetry.ts` and `shell-instance-state.ts` are unchanged since
`a49b3fc93e86`. `package-lock.json.gz` is the unchanged upstream lockfile
compressed with gzip (timestamp zero). Overlay on upstream-1270eeb5425c and
upstream-87266a2d7ed9 for patch regression tests; the other patched files are
unchanged and the upstream license is in the base fixture.

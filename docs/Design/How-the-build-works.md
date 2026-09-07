# How the build works

## Source and patches

`prepare-source.sh` resolves GitHub's newest **published stable release**, performs
a shallow clone and applies `dist/all` followed by the target patch section.
Raw repository tags are deliberately not used for the default: upstream can tag
draft releases whose source still reports the preceding version. Every patch
must have a matching checksum and explanation.

Published upstream tags also identify the source commit *before* mongosh's
release `PackageBumper` writes the release version. After `npm ci` has validated
the pristine lockfile, `set-source-version.mjs` performs the same relevant edits:
the CLI package version and shell API version constant. The resulting bundle
must report the requested version or the job stops before uploading anything.

## One bundle, existing Node ports

Upstream's dependency-aware `compile-cli` task first compiles `cli-repl` and
every internal `@mongosh/*` workspace it imports. Merely running the workspace's
webpack task after `npm ci` is insufficient: npm links the workspaces but their
generated JavaScript and TypeScript declarations do not exist yet. The
`@mongosh/cli-repl` webpack task then produces `mongosh.js`. JavaScript is
architecture independent, so it is built once. `package-target.sh` downloads
the matching executable and checksum from the newest `wekan/node-patches`
release, verifies it, and packages that unmodified Node runtime with the bundle
and a relative launcher. This avoids boxednode rebuilding Node/V8 fourteen times.
The bundle is executed with `--version` before packaging, and a requested tag is
rejected if the built program reports another version.

The package is not considered runtime-verified merely because it was assembled.
Release consumers and FerretDB integration must run `mongosh --version` and a
real command against FerretDB on the target architecture. Native addons used by
optional Kerberos, encryption, system-keychain and machine-ID features need
target-specific builds before those features can be claimed for a new port.

## Releases

Release All builds one source bundle, fans out sixteen packages, checksums each
archive and accumulates them on the upstream-version tag. Release All Missing
audits both the archive and checksum so a half-uploaded target is never called
complete. GitHub logs name every missing target explicitly.

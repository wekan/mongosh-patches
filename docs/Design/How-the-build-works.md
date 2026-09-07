# How the build works

## Source and patches

`resolve-source.mjs` reads the newest upstream `main` commit from GitHub once.
`prepare-source.sh` fetches its full immutable SHA, checks that the resulting
checkout matches, and applies checksum-verified patches in `dist/all` followed
by the target patch section. The release identifier is `main-` plus the first
12 hexadecimal characters of that commit. Arbitrary refs and malformed source
identifiers are rejected before invoking Git.

After `npm ci` validates the original lockfile, `set-source-version.mjs` stamps
the CLI package and shell API constant with a valid semantic prerelease version:
`<upstream-version>-main.<short-hash>`. The release itself is named `main-HASH`.
`mongosh-source.json` records the full commit SHA in the shared build artifact,
the GitHub release, and every target archive. The bundle must report its stamped
version or the build stops before uploading artifacts.

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

Release All builds one immutable main source bundle, filters the sixteen-target
registry using one Node release's complete runtime/checksum pairs, and packages
the available targets under `main-HASH`. Unavailable prerequisites appear in the
job summary and remain registered for later retries.

Release All Missing accepts an existing `main-HASH`, resolves the matching
immutable commit, and verifies the prefix. It audits both archive and checksum,
so a half-uploaded target is never called complete. Source resolution never uses
the current main head for a repair. It also waits for a complete Node runtime
pair before scheduling that target. Neither workflow substitutes another
architecture or falls back to an older Node runtime.

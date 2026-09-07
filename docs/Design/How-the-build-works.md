# How the build works

## Source and patches

`prepare-source.sh` resolves the newest stable upstream tag, performs a shallow
clone and applies `dist/all` followed by the target patch section. Every patch
must have a matching checksum and explanation.

## One bundle, existing Node ports

Upstream's `@mongosh/cli-repl` webpack task produces `mongosh.js`. JavaScript is
architecture independent, so it is built once. `package-target.sh` downloads
the matching executable and checksum from the newest `wekan/node-patches`
release, verifies it, and packages that unmodified Node runtime with the bundle
and a relative launcher. This avoids boxednode rebuilding Node/V8 fourteen times.

The package is not considered runtime-verified merely because it was assembled.
Release consumers and FerretDB integration must run `mongosh --version` and a
real command against FerretDB on the target architecture. Native addons used by
optional Kerberos, encryption, system-keychain and machine-ID features need
target-specific builds before those features can be claimed for a new port.

## Releases

Release All builds one source bundle, fans out fourteen packages, checksums each
archive and accumulates them on the upstream-version tag. Release All Missing
audits both the archive and checksum so a half-uploaded target is never called
complete. GitHub logs name every missing target explicitly.

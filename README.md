# mongosh-patches

Patch-only build and multi-platform packaging for
[MongoDB Shell](https://github.com/mongodb-js/mongosh). It follows the newest
commit of upstream `main`, applies checksum-verified patches from `dist/`, builds
one architecture-independent production bundle, and combines it with the
matching ready-made Node.js runtime from
[wekan/node-patches releases](https://github.com/wekan/node-patches/releases).
Node.js and V8 are never rebuilt here.

## Telemetry is removed, not disabled

`dist/all/remove-telemetry.patch` applies to every target. It makes
`resolveToggleableAnalytics()` return the no-op analytics sink
unconditionally, so `TelemetryClient`/`ThrottledAnalytics` are never
constructed and no HTTP request is ever made, regardless of the configured
endpoint or `MONGOSH_TELEMETRY_ENDPOINT`. It also stops the native
machine-id lookup that only existed to key telemetry throttle state, and
replaces the upstream "pseudo-anonymous usage data is collected ... you can
opt out by running disableTelemetry()" startup banner with a notice that
this fork does not collect or send anything. `disableTelemetry()` still
exists as a no-op for script compatibility.

The same patch also fixes mongosh's config/history file handling in a
container that runs as a user with no home directory entry: `os.homedir()`
then resolves to an unwritable path like `/nonexistent`, which previously
produced a startup `EACCES ... mkdir '/nonexistent'` warning and a "Could
not open history file" error on every session. Config/log/history storage
now falls back to a writable directory under the OS temp dir when the home
directory is not writable.

Each build resolves upstream `main` once, fetches that exact full commit, and
names the release/tag `main-<12-character-hash>` (for example,
`main-79267331504d`). A `mongosh-source.json` records the full SHA in the release
and inside every package. The executable reports the upstream semantic version
with `-main.<hash>` appended, such as `2.10.0-main.79267331504d`.
Release All Missing accepts the existing `main-HASH` name and rebuilds that exact
source even after upstream main advances; it never silently switches commits.

Release assets are `mongosh-<target>.tgz` or `.zip`, each with a
`.sha256sum`. The target registry includes: `amd64`, `arm64`, `armhf`, `armv6`, `armv7`, `i386`, `ppc64le`,
`s390x`, `riscv64`, `loong64`, `win64`, `win-arm64`, `win32`, `mac-amd64`,
`mac-arm64` and `freebsd-x64`.

Both workflows and `build.sh all` intersect this registry with the runtime AND
checksum assets in one selected node-patches release before scheduling packages.
Unavailable targets are reported in the job log and workflow summary; they are
not built or published. Release All Missing checks them again on its next run.
At node-patches v24.20.0, Windows ARM64 and FreeBSD x64 have build definitions but
no published runtimes, so the other fourteen targets can complete independently.
No older runtime, differently named architecture, or unverified binary is used as
a fallback. These two packages remain blocked until node-patches publishes them.

```sh
./build.sh bundle
./build.sh arm64
./build.sh all
./tests/workflow-logic.sh
```

The repository build files are MIT licensed. Upstream mongosh and its bundled
notices retain their own Apache-2.0 and dependency licenses in release packages.
Maintainer/contributor and never-push rules come from WeKan's root `AGENTS.md`.

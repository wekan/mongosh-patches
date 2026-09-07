# mongosh-patches

Patch-only build and multi-platform packaging for
[MongoDB Shell](https://github.com/mongodb-js/mongosh). It follows the newest
stable upstream `2.x` tag, applies checksum-verified patches from `dist/`, builds
one architecture-independent production bundle, and combines it with the
matching ready-made Node.js runtime from
[wekan/node-patches releases](https://github.com/wekan/node-patches/releases).
Node.js and V8 are never rebuilt here.

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

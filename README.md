# mongosh-patches

Patch-only build and multi-platform packaging for
[MongoDB Shell](https://github.com/mongodb-js/mongosh). It follows the newest
stable upstream `2.x` tag, applies checksum-verified patches from `dist/`, builds
one architecture-independent production bundle, and combines it with the
matching ready-made Node.js runtime from
[wekan/node-patches releases](https://github.com/wekan/node-patches/releases).
Node.js and V8 are never rebuilt here.

Release assets are `mongosh-<target>.tgz` or `.zip`, each with a
`.sha256sum`. Supported target tokens are the intersection currently published
by node-patches: `amd64`, `arm64`, `armhf`, `armv6`, `armv7`, `i386`, `ppc64le`,
`s390x`, `riscv64`, `loong64`, `win64`, `win-arm64`, `win32`, `mac-amd64`,
`mac-arm64` and `freebsd-x64`.

```sh
./build.sh bundle
./build.sh arm64
./build.sh all
./tests/workflow-logic.sh
```

The repository build files are MIT licensed. Upstream mongosh and its bundled
notices retain their own Apache-2.0 and dependency licenses in release packages.
Maintainer/contributor and never-push rules come from WeKan's root `AGENTS.md`.

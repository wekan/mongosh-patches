# Platforms

- [Releases](https://github.com/wekan/mongosh-patches/releases)
- [Upstream mongosh](https://github.com/mongodb-js/mongosh)
- [Node runtimes](https://github.com/wekan/node-patches/releases)
- [Build design](docs/Design/How-the-build-works.md)

<details>
<summary>Version</summary>

The release tag is the upstream mongosh tag. Each archive records that one
JavaScript bundle and an independently checksum-verified Node runtime from the
newest node-patches release.

</details>

# TODO Later

<details>
<summary>Carried to a future release.</summary>

- Build and test target-native optional addons for Kerberos, client-side field
  encryption, keychains and machine identity on every additional Node port.
- Add FreeBSD and Windows ARM64 after node-patches publishes matching runtimes.

</details>

# Upcoming mongosh-patches release

**In short:** Build upstream mongosh once and package it for every ready-made
`wekan/node-patches` Node.js target without rebuilding Node or V8.

<details>
<summary>Package mongosh for Windows ARM64 and FreeBSD x64</summary>

The sixteen-target registries now include `win-arm64` and `freebsd-x64`, using
the matching checksum-verified node-patches runtime and the existing portable
mongosh bundle. Both full and missing-only workflows resolve one authenticated
Node release for their complete matrix, avoiding concurrent unauthenticated API
queries. Offline coverage keeps the workflow, scripts, menus and asset mapping
in agreement.

</details>

<details>
<summary>Use the published Windows checksums and one shared Node release</summary>

Windows packages now verify `node-win32.exe` and `node-win64.exe` with the
checksum filenames that node-patches actually publishes. Release All resolves
the Node release once with its authenticated workflow token and passes the same
tag to all fourteen package jobs, avoiding unauthenticated GitHub API rate
limits during the parallel matrix.

</details>

<details>
<summary>Compile internal mongosh workspaces before bundling</summary>

The bundle job now runs upstream's dependency-aware `compile-cli` target before
the `cli-repl` webpack task. This creates the JavaScript and TypeScript
declarations for every imported `@mongosh/*` workspace instead of failing with
`TS2307: Cannot find module` immediately after `npm ci`. Automatic releases now
use GitHub's newest published stable release rather than the greatest raw Git
tag, and execute the bundle with `--version` so draft or mismatched source cannot
be published under an incorrect version.

</details>

<details>
<summary>Initial patch-only multi-platform release build</summary>

The source resolver follows stable upstream tags. Patch checksums are verified
before applying. Release All shares one production JavaScript bundle across
fourteen packages, while each package downloads and verifies its exact
node-patches runtime. Archives and their checksums accumulate on one release.

</details>

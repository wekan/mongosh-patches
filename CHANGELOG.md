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

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
<summary>Initial patch-only multi-platform release build</summary>

The source resolver follows stable upstream tags. Patch checksums are verified
before applying. Release All shares one production JavaScript bundle across
fourteen packages, while each package downloads and verifies its exact
node-patches runtime. Archives and their checksums accumulate on one release.

</details>

# Patch format

Every `dist/<section>/<name>.patch` has:

- `<name>.sha256sum`, generated with `sha256sum <name>.patch` from that directory;
- `<name>.md`, explaining the upstream fault, affected targets and verification.

`dist/all` applies first. A target-token section applies second. A checksum
mismatch or failed `git apply` stops the build before dependencies are installed.

# Patch sets

This repository carries patches, not a fork of mongosh. Put patches shared by
every target in `dist/all/` as a matching `.patch`, `.sha256sum` and `.md` trio.
Target-specific directories use the release token (`armv6`, `i386`, and so on).
The preparation script verifies each checksum before applying the patch.

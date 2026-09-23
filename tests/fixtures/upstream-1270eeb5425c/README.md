# Upstream patch fixture

The source files here are copied unchanged from mongodb-js/mongosh commit
`1270eeb5425c13c10f9b25241cff43c1c4b82e6f`, which was also upstream main during
the September 23, 2026 telemetry audit. The upstream LICENSE is included.

`package-lock.json.gz` is the unchanged upstream lockfile compressed with gzip
(timestamp zero); the regression suite expands it before applying the patch.
The remaining files are plain upstream source so reviewers can inspect them.

Keep this fixture independent of the patch. It covers the old comment-context
failure and the complete removal of the telemetry implementation. New patch
hunks must apply to upstream source, not to a fixture generated from the patch.

# Remove telemetry and tolerate an unwritable home directory

Applies to every target. Analytics resolves to the no-op sink regardless of the
configured endpoint; device fingerprinting is removed and the startup notice
states that no usage data is sent. Config/history paths fall back to the OS temp
directory when the home directory is unwritable.

The September 23 build of upstream commit
`1270eeb5425c13c10f9b25241cff43c1c4b82e6f` failed because the analytics hunk
expected an older comment. The hunk now matches that source and the SHA-256
sidecar is refreshed. Application remains strict: unexpected source changes fail
the build instead of skipping telemetry removal.

Run `bash tests/workflow-logic.sh` with Node.js 26. Its offline patch regression
suite applies every hunk to the unchanged upstream fixture, executes the patched
analytics resolver with inaccessible telemetry parameters, checks the other
patched files, and verifies that incompatible source fails without partial edits.

# Upstream patch fixture

These four TypeScript source files are copied unchanged from mongodb-js/mongosh
commit `1270eeb5425c13c10f9b25241cff43c1c4b82e6f`, the source revision in the
September 23, 2026 failed bundle job. The upstream LICENSE is included.

The fixture deliberately retains upstream's analytics comment: the earlier
patch expected different wording there and could not apply. Keep this fixture
independent of the patch so an invalid hunk cannot silently update its own test.

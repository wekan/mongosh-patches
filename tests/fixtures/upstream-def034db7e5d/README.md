# Upstream patch fixture overlay

Unchanged files from mongodb-js/mongosh commit
`def034db7e5d2924dcf012ea9beacb90aae8388f`, the source in the failed build
where mongosh 2.14.0 bumped `@mongosh/autocomplete` and `editor` to 5.9.5 -
moving the context of the manifest and lockfile hunks - and `cli-repl.ts`
gained a `hasTerminalInput` getter that decides which sessions are tracked.
`package-lock.json.gz` is the unchanged upstream lockfile compressed with gzip
(timestamp zero). Overlay on upstream-1270eeb5425c and upstream-87266a2d7ed9
for patch regression tests; the other patched files are unchanged and the
upstream license is in the base fixture.

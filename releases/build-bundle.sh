#!/usr/bin/env bash
set -euo pipefail
: "${MONGOSH_VERSION:?MONGOSH_VERSION is required}"
npm ci --ignore-scripts=false
# Upstream tags point at the source commit from which the release is prepared;
# its cli package and shell constant still contain the preceding version. Apply
# the same two relevant edits as upstream's PackageBumper after npm ci has
# validated the untouched lockfile, then verify the executable below.
node "$(dirname "$0")/set-source-version.mjs" "$MONGOSH_VERSION"
# cli-repl imports the other @mongosh workspaces through their generated dist
# declarations. npm ci links those workspaces but does not compile them. Use
# upstream's dependency-aware target before invoking cli-repl's webpack task;
# compiling cli-repl alone produces TS2307 for every internal package.
npm run compile-cli
npm run webpack-build --workspace @mongosh/cli-repl
test -s packages/cli-repl/dist/mongosh.js
actual_version="$(node packages/cli-repl/dist/mongosh.js --version)"
if [ -n "${MONGOSH_VERSION:-}" ] && [ "$actual_version" != "$MONGOSH_VERSION" ]; then
  printf 'Built mongosh reports %s, expected %s from %s\n' \
    "$actual_version" "$MONGOSH_VERSION" "${MONGOSH_REF:-the requested tag}" >&2
  exit 2
fi
mkdir -p out
cp packages/cli-repl/dist/mongosh.js out/mongosh.js
cp LICENSE-mongosh out/LICENSE-mongosh 2>/dev/null || cp LICENSE out/LICENSE-mongosh
cp THIRD_PARTY_NOTICES.md out/THIRD_PARTY_NOTICES.md
sha256sum out/mongosh.js > out/mongosh.js.sha256sum

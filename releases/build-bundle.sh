#!/usr/bin/env bash
set -euo pipefail
npm ci --ignore-scripts=false
npm run webpack-build --workspace @mongosh/cli-repl
test -s packages/cli-repl/dist/mongosh.js
mkdir -p out
cp packages/cli-repl/dist/mongosh.js out/mongosh.js
cp LICENSE-mongosh out/LICENSE-mongosh 2>/dev/null || cp LICENSE out/LICENSE-mongosh
cp THIRD_PARTY_NOTICES.md out/THIRD_PARTY_NOTICES.md
sha256sum out/mongosh.js > out/mongosh.js.sha256sum

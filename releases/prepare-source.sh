#!/usr/bin/env bash
set -euo pipefail
patches="${1:?patch checkout required}"
identity="$(node "$patches/releases/resolve-source.mjs" "${2:-}")"
commit="$(node -e 'console.log(JSON.parse(process.argv[1]).commit)' "$identity")"
ref="$(node -e 'console.log(JSON.parse(process.argv[1]).release)' "$identity")"
git init mongoshsrc
git -C mongoshsrc remote add origin https://github.com/mongodb-js/mongosh.git
git -C mongoshsrc fetch --depth 1 origin "$commit"
git -C mongoshsrc checkout --detach FETCH_HEAD
[ "$(git -C mongoshsrc rev-parse HEAD)" = "$commit" ] || {
  echo 'Fetched source differs from the resolved upstream commit' >&2; exit 2;
}
shopt -s dotglob nullglob
mv mongoshsrc/* .
rmdir mongoshsrc
for section in all "${TARGET:-}"; do
  [ -n "$section" ] || continue
  for patch in "$patches/dist/$section"/*.patch; do
    [ -e "$patch" ] || continue
    (cd "$(dirname "$patch")" && sha256sum -c "$(basename "$patch" .patch).sha256sum")
    git apply "$patch"
  done
done
base_version="$(node -p "require('./packages/cli-repl/package.json').version")"
[[ "$base_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Unexpected upstream package version' >&2; exit 2; }
version="$base_version-main.${commit:0:12}"
printf '%s\n' "$identity" > mongosh-source.json
printf 'MONGOSH_VERSION=%s\n' "$version" | tee -a "${GITHUB_ENV:-/dev/null}"
printf 'MONGOSH_REF=%s\n' "$ref" | tee -a "${GITHUB_ENV:-/dev/null}"
printf 'MONGOSH_COMMIT=%s\n' "$(git rev-parse HEAD)" | tee -a "${GITHUB_ENV:-/dev/null}"

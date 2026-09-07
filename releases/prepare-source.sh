#!/usr/bin/env bash
set -euo pipefail
patches="${1:?patch checkout required}"
ref="${2:-}"
[ -n "$ref" ] || ref="$(bash "$patches/releases/newest-release.sh" "$patches")"
git clone --depth 1 --branch "$ref" https://github.com/mongodb-js/mongosh.git mongoshsrc
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
printf 'MONGOSH_VERSION=%s\n' "${ref#v}" | tee -a "${GITHUB_ENV:-/dev/null}"
printf 'MONGOSH_REF=%s\n' "$ref" | tee -a "${GITHUB_ENV:-/dev/null}"
printf 'MONGOSH_COMMIT=%s\n' "$(git rev-parse HEAD)" | tee -a "${GITHUB_ENV:-/dev/null}"

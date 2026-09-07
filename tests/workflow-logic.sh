#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
ok(){ printf 'ok - %s\n' "$1"; }
bad(){ printf 'FAIL - %s\n' "$1"; fails=$((fails+1)); }

for script in releases/newest-release.sh releases/prepare-source.sh releases/build-bundle.sh releases/package-target.sh build.sh; do
  bash -n "$root/$script" && ok "$script parses" || bad "$script does not parse"
done

all="$root/.github/workflows/release-all.yml"
missing="$root/.github/workflows/release-all-missing.yml"
for target in amd64 arm64 armhf armv6 armv7 i386 ppc64le s390x riscv64 loong64 win64 win32 mac-amd64 mac-arm64; do
  grep -q "$target" "$all" && ok "Release All names $target" || bad "Release All misses $target"
  grep -q "$target" "$missing" && ok "Missing audit names $target" || bad "Missing audit misses $target"
done
grep -q 'wekan/node-patches' "$root/releases/package-target.sh" && ok 'packages use node-patches releases' || bad 'node-patches source absent'
grep -q 'sha256sum -c' "$root/releases/package-target.sh" && ok 'Node checksum is enforced' || bad 'Node checksum is not enforced'
grep -q 'npm run webpack-build --workspace @mongosh/cli-repl' "$root/releases/build-bundle.sh" && ok 'upstream production bundle is used' || bad 'wrong bundle build'
grep -q 'if-no-files-found: error' "$all" && ok 'empty artifacts fail loudly' || bad 'empty artifacts may pass'
grep -q 'gh release upload.*--clobber' "$all" && ok 'Release All accumulates safely' || bad 'release accumulation absent'
grep -q 'grep -qxF.*sha256sum' "$missing" && ok 'missing audit requires checksum pair' || bad 'half-upload check absent'

[ "$fails" -eq 0 ] || exit 1

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
compile_line=$(grep -n '^npm run compile-cli$' "$root/releases/build-bundle.sh" | cut -d: -f1)
bundle_line=$(grep -n '^npm run webpack-build --workspace @mongosh/cli-repl$' "$root/releases/build-bundle.sh" | cut -d: -f1)
if [ -n "$compile_line" ] && [ -n "$bundle_line" ] && [ "$compile_line" -lt "$bundle_line" ]; then
  ok 'cli workspace dependencies compile before webpack'
else
  bad 'cli workspace dependencies are not compiled before webpack'
fi
grep -q 'npm run webpack-build --workspace @mongosh/cli-repl' "$root/releases/build-bundle.sh" && ok 'upstream production bundle is used' || bad 'wrong bundle build'
grep -q 'api.github.com/repos/mongodb-js/mongosh/releases/latest' "$root/releases/newest-release.sh" && ok 'newest defaults to the published stable release' || bad 'newest may select an unpublished tag'
if ! grep -q 'git ls-remote --tags' "$root/releases/newest-release.sh"; then
  ok 'draft and future tags are not treated as releases'
else
  bad 'raw Git tags still select the default release'
fi
grep -q 'actual_version=.*--version' "$root/releases/build-bundle.sh" && ok 'bundle version is read back' || bad 'bundle version is not verified'
grep -q 'actual_version.*MONGOSH_VERSION' "$root/releases/build-bundle.sh" && ok 'wrong-tag bundle fails' || bad 'wrong-tag bundle may be published'
grep -q 'set-source-version.mjs.*MONGOSH_VERSION' "$root/releases/build-bundle.sh" && ok 'tag version is applied to release source' || bad 'source keeps the preceding version'
grep -q 'MONGOSH_VERSION="${ref#v}"' "$root/build.sh" && ok 'local bundle exports its selected version' || bad 'local bundle omits its version'
node --check "$root/releases/set-source-version.mjs" && ok 'source version helper parses' || bad 'source version helper does not parse'
grep -q 'if-no-files-found: error' "$all" && ok 'empty artifacts fail loudly' || bad 'empty artifacts may pass'
grep -q 'gh release upload.*--clobber' "$all" && ok 'Release All accumulates safely' || bad 'release accumulation absent'
grep -q 'grep -qxF.*sha256sum' "$missing" && ok 'missing audit requires checksum pair' || bad 'half-upload check absent'

[ "$fails" -eq 0 ] || exit 1

#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
ok(){ printf 'ok - %s\n' "$1"; }
bad(){ printf 'FAIL - %s\n' "$1"; fails=$((fails+1)); }

for script in releases/newest-release.sh releases/prepare-source.sh releases/build-bundle.sh releases/package-target.sh releases/upload-release-assets.sh build.sh; do
  bash -n "$root/$script" && ok "$script parses" || bad "$script does not parse"
done

all="$root/.github/workflows/release-all.yml"
missing="$root/.github/workflows/release-all-missing.yml"
for target in amd64 arm64 armhf armv6 armv7 i386 ppc64le s390x riscv64 loong64 win64 win-arm64 win32 mac-amd64 mac-arm64 freebsd-x64; do
  grep -q "$target" "$all" && ok "Release All names $target" || bad "Release All misses $target"
  grep -q "$target" "$missing" && ok "Missing audit names $target" || bad "Missing audit misses $target"
done
grep -q 'wekan/node-patches' "$root/releases/package-target.sh" && ok 'packages use node-patches releases' || bad 'node-patches source absent'
grep -q 'sha256sum -c' "$root/releases/package-target.sh" && ok 'Node checksum is enforced' || bad 'Node checksum is not enforced'
grep -q 'checksum_asset="node-\$target.sha256sum"' "$root/releases/package-target.sh" && ok 'Windows uses published checksum names' || bad 'Windows checksum name includes the executable suffix'
grep -q 'win64|win-arm64|win32' "$root/releases/package-target.sh" && ok 'Windows ARM64 package uses its Node release asset' || bad 'Windows ARM64 package target absent'
grep -q 'freebsd-x64.*node-freebsd-x64' "$root/releases/package-target.sh" && ok 'FreeBSD package uses its Node release asset' || bad 'FreeBSD package target absent'
grep -q 'node-version:.*steps.meta.outputs.node-version' "$all" && ok 'Node release is resolved once' || bad 'Node release is not exposed by bundle job'
grep -q 'NODE_PATCHES_VERSION:.*needs.bundle.outputs.node-version' "$all" && ok 'all packages share one Node release' || bad 'package jobs query Node releases independently'
grep -q 'NODE_PATCHES_VERSION:.*needs.audit.outputs.node-version' "$missing" && ok 'missing packages share one Node release' || bad 'missing package jobs query Node releases independently'
compile_line=$(grep -n '^npm run compile-cli$' "$root/releases/build-bundle.sh" | cut -d: -f1)
bundle_line=$(grep -n '^npm run webpack-build --workspace @mongosh/cli-repl$' "$root/releases/build-bundle.sh" | cut -d: -f1)
if [ -n "$compile_line" ] && [ -n "$bundle_line" ] && [ "$compile_line" -lt "$bundle_line" ]; then
  ok 'cli workspace dependencies compile before webpack'
else
  bad 'cli workspace dependencies are not compiled before webpack'
fi
grep -q 'npm run webpack-build --workspace @mongosh/cli-repl' "$root/releases/build-bundle.sh" && ok 'upstream production bundle is used' || bad 'wrong bundle build'
grep -q 'resolve-source.mjs' "$root/releases/newest-release.sh" && ok 'newest resolves upstream main' || bad 'newest source resolver absent'
grep -q 'fetch --depth 1 origin "$commit"' "$root/releases/prepare-source.sh" && ok 'source fetch uses immutable commit' || bad 'source fetch is mutable'
grep -q "require('node:path').resolve(process.argv\[1\])" "$root/releases/prepare-source.sh" && ok 'telemetry audit review file resolves as filesystem path' || bad 'telemetry audit review file is loaded as a package name'
grep -q 'actual_version=.*--version' "$root/releases/build-bundle.sh" && ok 'bundle version is read back' || bad 'bundle version is not verified'
grep -q 'actual_version.*MONGOSH_VERSION' "$root/releases/build-bundle.sh" && ok 'wrong-tag bundle fails' || bad 'wrong-tag bundle may be published'
grep -q 'set-source-version.mjs.*MONGOSH_VERSION' "$root/releases/build-bundle.sh" && ok 'tag version is applied to release source' || bad 'source keeps the preceding version'
grep -q 'source "$work/source.env"' "$root/build.sh" && ok 'local bundle uses resolved main identity' || bad 'local bundle omits its version'
node --check "$root/releases/set-source-version.mjs" && ok 'source version helper parses' || bad 'source version helper does not parse'
grep -q 'if-no-files-found: error' "$all" && ok 'empty artifacts fail loudly' || bad 'empty artifacts may pass'
grep -q 'gh release upload.*--clobber' "$root/releases/upload-release-assets.sh" && ok 'Release All accumulates safely' || bad 'release accumulation absent'
grep -q 'seq 1 "$attempts"' "$root/releases/upload-release-assets.sh" && ok 'release uploads are retried' || bad 'release uploads are not retried'
# Each build job attaches its own files as soon as it has built and checked
# them; the final job only verifies the release and never uploads packages.
for wf in "$all" "$missing"; do
  name=$(basename "$wf")
  pkg_job=$(awk '/^  packages:/{f=1;next} /^  [a-z-]+:/{f=0} f' "$wf")
  final_job=$(awk '/^  publish:/{f=1;next} /^  [a-z-]+:/{f=0} f' "$wf")
  last_step=$(printf '%s\n' "$pkg_job" | awk '/^      - /{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}')
  printf '%s' "$last_step" | grep -q 'upload-release-assets.sh "$VERSION"' && ok "$name packages attach their own files last" || bad "$name packages do not attach their own files"
  printf '%s' "$pkg_job" | grep -q 'contents: write' && ok "$name package jobs may write releases" || bad "$name package jobs lack contents: write"
  printf '%s' "$final_job" | grep -q 'gh release upload\|upload-release-assets\|download-artifact' && bad "$name final job still collects or uploads packages" || ok "$name final job does not upload packages"
  printf '%s' "$final_job" | grep -q 'sha256sum -c' && ok "$name final job verifies published checksums" || bad "$name final job skips checksum verification"
done
# Cancelling a run must not throw away finished packages: every attach step
# runs under always() but only after its own build step succeeded, and the
# final job runs under always() once the release-creating job succeeded.
# Prints one problem per line; empty output means the workflow is cancel-safe.
cancel_problems() {
  local wf="$1" job attach final
  for job in packages bundle; do
    job_text=$(awk -v j="  $job:" '$0==j{f=1;next} /^  [a-z-]+:/{f=0} f' "$wf")
    attach=$(printf '%s\n' "$job_text" | awk '/^      - /{if(buf ~ /upload-release-assets/) out=out buf; buf=""} {buf=buf $0 "\n"} END{if(buf ~ /upload-release-assets/) out=out buf; printf "%s", out}')
    [ -n "$attach" ] || continue
    ifs=$(printf '%s' "$attach" | grep -E '^        if:' || true)
    [ -n "$ifs" ] || { echo "$job attach step has no condition"; continue; }
    printf '%s\n' "$ifs" | grep -q 'always()' || echo "$job attach step is skipped when the run is cancelled"
    ids=$(printf '%s' "$ifs" | grep -o "steps\.[a-z-]*\.outcome == 'success'" | sed "s/steps\.\([a-z-]*\)\..*/\1/" || true)
    [ -n "$ids" ] || echo "$job attach step does not require its build step to succeed"
    for id in $ids; do
      printf '%s' "$job_text" | grep -qE "^ +(- )?id: $id$" || echo "$job attach step checks unknown step id $id"
    done
  done
  final=$(awk '/^  publish:/{f=1;next} /^  [a-z-]+:/{f=0} f' "$wf" | grep -E '^    if:' || true)
  printf '%s' "$final" | grep -q 'always()' || echo "final job is skipped when the run is cancelled"
  printf '%s' "$final" | grep -q '!cancelled()' && echo "final job uses !cancelled()"
  printf '%s' "$final" | grep -qE "needs\.(bundle|audit)\.result == 'success'" || echo "final job does not require the release-creating job"
  awk '/^  publish:/{f=1;next} /^  [a-z-]+:/{f=0} f' "$wf" | grep -q 'PACKAGES_RESULT: ${{ needs.packages.result }}' \
    || echo "final job cannot tell a cancelled run from a lost package"
  return 0
}
for wf in "$all" "$missing"; do
  name=$(basename "$wf")
  problems=$(cancel_problems "$wf")
  [ -z "$problems" ] && ok "$name attaches finished packages and verifies them after cancellation" || bad "$name is not cancel-safe: $problems"
done
grep -q 'id: build' "$all" && grep -q "steps.build.outcome == 'success'" "$all" && ok 'bundle attach waits for a successful bundle build' || bad 'bundle attach ignores its build outcome'
# Negative tests: each regression must be caught by cancel_problems.
neg_dir=$(mktemp -d "${TMPDIR:-/tmp}/workflow-logic.XXXXXX")
neg() {
  local label="$1" wf="$2" expr="$3" out="$neg_dir/case.yml"
  sed -E "$expr" "$wf" > "$out"
  [ -n "$(cancel_problems "$out")" ] && ok "negative: $label is rejected" || bad "negative: $label is accepted"
}
neg 'attach step without always()' "$all" "s/if: \\$\\{\\{ always\(\) && inputs.publish && steps.package/if: \${{ inputs.publish \&\& steps.package/"
neg 'missing attach step without always()' "$missing" "s/if: \\$\\{\\{ always\(\) && steps.package/if: \${{ steps.package/"
neg 'attach step without build outcome' "$all" "s/ && steps.package.outcome == 'success'//"
neg 'bundle attach without always()' "$all" "s/if: \\$\\{\\{ always\(\) && inputs.publish && steps.build/if: \${{ inputs.publish \&\& steps.build/"
neg 'build step id removed' "$missing" "s/- id: package/-/"
neg 'final job with default condition' "$all" "s/^    if: \\$\\{\\{ always\(\) && inputs.publish && needs.bundle/    if: \${{ inputs.publish \&\& needs.bundle/"
neg 'final job with !cancelled()' "$missing" "s/^    if: \\$\\{\\{ always\(\) && needs.audit/    if: \${{ !cancelled() \&\& needs.audit/"
neg 'final job without release-job check' "$missing" "s/ && needs.audit.result == 'success'//"
rm -rf "$neg_dir"
bundle_job=$(awk '/^  bundle:/{f=1;next} /^  [a-z-]+:/{f=0} f' "$all")
printf '%s' "$bundle_job" | grep -q 'gh release create' && printf '%s' "$bundle_job" | grep -q 'upload-release-assets.sh "$VERSION" out/mongosh-source.json' \
  && ok 'bundle job creates the release and attaches its manifest' || bad 'release is not created before package jobs'
grep -q 'plan-targets.mjs node-release.json existing' "$missing" && ok 'missing audit uses runtime and archive pair planner' || bad 'missing planner absent'
node --test "$root/tests/plan-targets.test.mjs" && ok 'runtime availability plans pass' || bad 'runtime availability plans failed'
grep -q 'fromJSON(needs.bundle.outputs.targets)' "$all" && ok 'full matrix uses available runtimes' || bad 'full matrix is unconditional'

grep -q 'plan-targets.mjs' "$root/build.sh" && ok 'local all build checks published runtime pairs' || bad 'local all build unconditionally schedules missing runtimes'
node --test "$root/tests/source-identity.test.mjs" && ok 'source identity tests pass' || bad 'source identity tests failed'

# Telemetry-removal patch: verified checksum, applies to a fresh upstream
# checkout, and actually removes the network send / device fingerprinting /
# opt-out banner rather than just adding a flag somewhere.
telemetry_patch="$root/dist/all/remove-telemetry.patch"
if [ -f "$telemetry_patch" ]; then
  (cd "$(dirname "$telemetry_patch")" && sha256sum -c "$(basename "$telemetry_patch" .patch).sha256sum" >/dev/null) \
    && ok 'telemetry-removal patch checksum matches' || bad 'telemetry-removal patch checksum mismatch'
  grep -q 'export async function resolveToggleableAnalytics' "$telemetry_patch" \
    && grep -q "analytics: new ToggleableAnalytics(), telemetryEndpoint: ''" "$telemetry_patch" \
    && ok 'telemetry-removal patch makes analytics an unconditional no-op' \
    || bad 'telemetry-removal patch does not neutralize the analytics sink'
  grep -q 'resolveWritableHomeBase' "$telemetry_patch" \
    && ok 'telemetry-removal patch adds a writable-home fallback' \
    || bad 'telemetry-removal patch is missing the home-directory fallback'
  grep -q 'No usage data is collected or sent by this build' "$telemetry_patch" \
    && ok 'telemetry-removal patch replaces the opt-out banner with a removed-not-disabled notice' \
    || bad 'telemetry-removal patch keeps the upstream opt-out banner'
  if ! grep -q '^+.*getMachineId' "$telemetry_patch" && grep -q "return 'unknown';" "$telemetry_patch"; then
    ok 'telemetry-removal patch drops native machine-id fingerprinting'
  else
    bad 'telemetry-removal patch still fingerprints the machine'
  fi
else
  bad 'dist/all/remove-telemetry.patch is missing'
fi

node --test "$root/tests/telemetry-patch.test.mjs" && ok 'upstream telemetry patch regression tests pass' || bad 'upstream telemetry patch regression tests failed'

node --test "$root/tests/telemetry-audit.test.mjs" && ok 'telemetry audit guards pass' || bad 'telemetry audit guards failed'

node --check "$root/tests/telemetry-runtime.test.mjs" && ok 'CLI telemetry smoke test parses' || bad 'CLI telemetry smoke test does not parse'

[ "$fails" -eq 0 ] || exit 1

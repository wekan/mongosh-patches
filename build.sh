#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
targets='amd64 arm64 armhf armv6 armv7 i386 ppc64le s390x riscv64 loong64 win64 win-arm64 win32 mac-amd64 mac-arm64 freebsd-x64'

build_bundle() {
  work="$(mktemp -d)"; trap 'rm -rf "$work"' RETURN
  ref="$(bash "$root/releases/newest-release.sh" "$root")"
  git clone --depth 1 --branch "$ref" https://github.com/mongodb-js/mongosh.git "$work/src"
  (cd "$work/src" && MONGOSH_REF="$ref" MONGOSH_VERSION="${ref#v}" \
    bash "$root/releases/build-bundle.sh")
  cp "$work/src/out/mongosh.js" "$root/mongosh.js"
}

build_target() {
  [ -s "$root/mongosh.js" ] || build_bundle
  (cd "$root" && PATCHES_ROOT="$root" bash releases/package-target.sh "$1" mongosh.js)
}

build_all() (
  plan_work="$(mktemp -d)"; trap 'rm -rf "$plan_work"' EXIT
  repo="${NODE_PATCHES_REPO:-wekan/node-patches}"
  endpoint=latest
  [ -z "${NODE_PATCHES_VERSION:-}" ] || endpoint="tags/$NODE_PATCHES_VERSION"
  curl -fsSL --retry 5 "https://api.github.com/repos/$repo/releases/$endpoint" > "$plan_work/release.json"
  node "$root/releases/plan-targets.mjs" "$plan_work/release.json" > "$plan_work/plan.json"
  NODE_PATCHES_VERSION="$(node -p "require(process.argv[1]).version" "$plan_work/plan.json")"
  export NODE_PATCHES_VERSION
  ready="$(node -p "require(process.argv[1]).targets.join(' ')" "$plan_work/plan.json")"
  [ -n "$ready" ] || { echo 'No complete Node runtime/checksum pairs are available.' >&2; exit 2; }
  for target in $ready; do build_target "$target"; done
)

case "${1:-menu}" in
  all) build_all ;;
  bundle) build_bundle ;;
  amd64|arm64|armhf|armv6|armv7|i386|ppc64le|s390x|riscv64|loong64|win64|win-arm64|win32|mac-amd64|mac-arm64|freebsd-x64) build_target "$1" ;;
  menu)
    printf '1) Build bundle\n2) Package current platform\n3) Package all targets\nSelection: '
    read -r choice
    case "$choice" in
      1) build_bundle ;;
      2) case "$(uname -s)-$(uname -m)" in Linux-x86_64) build_target amd64;; Linux-aarch64) build_target arm64;; Darwin-x86_64) build_target mac-amd64;; Darwin-arm64) build_target mac-arm64;; *) echo 'Unsupported current platform' >&2; exit 2;; esac ;;
      3) build_all ;;
      *) echo 'Unknown selection' >&2; exit 2 ;;
    esac ;;
  *) echo "Usage: $0 [menu|bundle|all|TARGET]" >&2; exit 2 ;;
esac

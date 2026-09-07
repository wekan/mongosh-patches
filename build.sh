#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
targets='amd64 arm64 armhf armv6 armv7 i386 ppc64le s390x riscv64 loong64 win64 win32 mac-amd64 mac-arm64'

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

case "${1:-menu}" in
  all) for target in $targets; do build_target "$target"; done ;;
  bundle) build_bundle ;;
  amd64|arm64|armhf|armv6|armv7|i386|ppc64le|s390x|riscv64|loong64|win64|win32|mac-amd64|mac-arm64) build_target "$1" ;;
  menu)
    printf '1) Build bundle\n2) Package current platform\n3) Package all targets\nSelection: '
    read -r choice
    case "$choice" in
      1) build_bundle ;;
      2) case "$(uname -s)-$(uname -m)" in Linux-x86_64) build_target amd64;; Linux-aarch64) build_target arm64;; Darwin-x86_64) build_target mac-amd64;; Darwin-arm64) build_target mac-arm64;; *) echo 'Unsupported current platform' >&2; exit 2;; esac ;;
      3) for target in $targets; do build_target "$target"; done ;;
      *) echo 'Unknown selection' >&2; exit 2 ;;
    esac ;;
  *) echo "Usage: $0 [menu|bundle|all|TARGET]" >&2; exit 2 ;;
esac

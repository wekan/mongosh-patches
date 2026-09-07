#!/usr/bin/env bash
# Combine the architecture-independent webpack bundle with an already-built
# Node executable from wekan/node-patches. No Node/V8 compilation happens here.
set -euo pipefail
target="${1:?target required}"
bundle="${2:?mongosh.js required}"
out="${OUT:-out}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
repo="${NODE_PATCHES_REPO:-wekan/node-patches}"
node_tag="${NODE_PATCHES_VERSION:-}"
[ -n "$node_tag" ] || node_tag="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -1)"
case "$target" in
  amd64) node_asset=node-x64 ;;
  arm64|armhf|armv6|armv7|i386|ppc64le|s390x|riscv64|loong64) node_asset="node-$target" ;;
  mac-amd64) node_asset=node-mac-x64 ;;
  mac-arm64) node_asset=node-mac-arm64 ;;
  win64|win32) node_asset="node-$target.exe" ;;
  *) echo "unsupported node-patches target: $target" >&2; exit 2 ;;
esac
base="https://github.com/$repo/releases/download/$node_tag"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fL --retry 5 -o "$tmp/$node_asset" "$base/$node_asset"
curl -fL --retry 5 -o "$tmp/$node_asset.sha256sum" "$base/$node_asset.sha256sum"
(cd "$tmp" && sha256sum -c "$node_asset.sha256sum")
pkg="$tmp/mongosh-$target"; mkdir -p "$pkg/bin" "$pkg/lib/mongosh"
node_name=node; [[ "$target" == win* ]] && node_name=node.exe
cp "$tmp/$node_asset" "$pkg/bin/$node_name"
cp "$bundle" "$pkg/lib/mongosh/mongosh.js"
cp "${PATCHES_ROOT:-.}/LICENSE" "$pkg/LICENSE-wekan-build"
if [[ "$target" == win* ]]; then
  cat > "$pkg/mongosh.bat" <<EOF
@echo off
"%~dp0bin\\node.exe" "%~dp0lib\\mongosh\\mongosh.js" %*
EOF
  (cd "$tmp" && zip -qr "$out/mongosh-$target.zip" "mongosh-$target")
  asset="mongosh-$target.zip"
else
  cat > "$pkg/mongosh" <<EOF
#!/bin/sh
HERE=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)
exec "\$HERE/bin/node" "\$HERE/lib/mongosh/mongosh.js" "\$@"
EOF
  chmod +x "$pkg/mongosh" "$pkg/bin/node"
  tar -C "$tmp" -czf "$out/mongosh-$target.tgz" "mongosh-$target"
  asset="mongosh-$target.tgz"
fi
(cd "$out" && sha256sum "$asset" > "$asset.sha256sum")
printf '%s\n' "$asset"

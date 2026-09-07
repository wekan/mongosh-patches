#!/usr/bin/env bash
# Compatibility entry point: print the immutable release name of upstream main.
set -euo pipefail
root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
node "$root/releases/resolve-source.mjs" "${2:-}" |
  node -e 'let s="";process.stdin.on("data",c=>s+=c);process.stdin.on("end",()=>console.log(JSON.parse(s).release))'

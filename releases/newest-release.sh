#!/usr/bin/env bash
set -euo pipefail
root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
override="${2:-}"
[ -n "$override" ] && { printf '%s\n' "$override"; exit; }
major="$(tr -d '[:space:]' < "$root/mongosh-major.txt")"
git ls-remote --tags --refs https://github.com/mongodb-js/mongosh.git 'v*' |
  sed -n "s#.*refs/tags/v\(${major}\.[0-9][0-9.]*\)\$#v\1#p" |
  sort -V | tail -1

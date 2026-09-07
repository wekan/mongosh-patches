#!/usr/bin/env bash
set -euo pipefail
root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
override="${2:-}"
[ -n "$override" ] && { printf '%s\n' "$override"; exit; }
major="$(tr -d '[:space:]' < "$root/mongosh-major.txt")"
tag="$(curl --fail --silent --show-error --location \
  https://api.github.com/repos/mongodb-js/mongosh/releases/latest |
  node -e "let input=''; process.stdin.on('data', chunk => input += chunk); process.stdin.on('end', () => { const release=JSON.parse(input); if (typeof release.tag_name !== 'string') process.exit(2); process.stdout.write(release.tag_name); });")"
if [[ ! "$tag" =~ ^v${major}\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Newest published stable mongosh release has unexpected tag: %s\n' "$tag" >&2
  exit 2
fi
printf '%s\n' "$tag"

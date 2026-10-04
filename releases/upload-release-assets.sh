#!/usr/bin/env bash
# Attach files to an existing GitHub Release as soon as the job that built and
# checked them has finished. Same-named assets are replaced, so a rerun of one
# job repairs only its own files. Transient API failures are retried.
set -euo pipefail
tag="${1:?usage: upload-release-assets.sh TAG FILE...}"
shift
[ "$#" -gt 0 ] || { echo '::error::no release files to attach' >&2; exit 1; }
for file in "$@"; do
  [ -f "$file" ] || { echo "::error::release file $file is missing" >&2; exit 1; }
done
attempts="${UPLOAD_ATTEMPTS:-5}"
for attempt in $(seq 1 "$attempts"); do
  if gh release upload "$tag" "$@" --clobber; then
    printf 'Attached to %s: %s\n' "$tag" "$*"
    exit 0
  fi
  echo "::warning::upload attempt $attempt of $attempts to $tag failed" >&2
  [ "$attempt" -lt "$attempts" ] && sleep $((attempt * 15))
done
echo "::error::could not attach $* to $tag after $attempts attempts" >&2
exit 1

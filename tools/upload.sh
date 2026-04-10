#!/bin/sh
set -e

RELEASE=$1
REPO=$2
FILE_PATTERN=$3

for f in $FILE_PATTERN; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  local_size=$(stat -c%s "$f")
  local_sha256=$(sha256sum "$f" | awk '{print $1}')

  remote=$(gh api "repos/$REPO/releases/tags/$RELEASE" --jq ".assets[] | select(.name == \"$name\") | .size, .digest" 2>/dev/null || true)
  remote_size=$(echo "$remote" | head -1)
  remote_sha256=$(echo "$remote" | tail -1 | sed 's/sha256://')

  if [ "$local_size" = "$remote_size" ] && [ "$local_sha256" = "$remote_sha256" ]; then
    echo "$name already uploaded with matching checksum, skipping"
    continue
  fi

  uploaded=false
  for i in 1 2 3 4 5; do
    echo "attempt $i: uploading $name (${local_size} bytes)"
    timeout 600 gh release upload "$RELEASE" --repo "$REPO" --clobber "$f" && uploaded=true && break || sleep 30
  done
  [ "$uploaded" = true ] || exit 1
done

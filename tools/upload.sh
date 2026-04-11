#!/bin/sh
set -e

RELEASE=$1
REPO=$2
FILE_PATTERN=$3

if gh release view "$RELEASE" --repo "$REPO" > /dev/null 2>&1; then
  echo "release $RELEASE already exists"
else
  echo "creating release $RELEASE"
  gh release create "$RELEASE" --repo "$REPO" --title "$RELEASE" --notes "$RELEASE"
fi

for f in $FILE_PATTERN; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  local_size=$(stat -c%s "$f")
  uploaded=false
  for i in 1 2 3 4 5; do
    echo "attempt $i: uploading $name (${local_size} bytes)"
    timeout 1800 gh release upload "$RELEASE" --repo "$REPO" --clobber "$f" && uploaded=true && break || sleep 30
  done
  [ "$uploaded" = true ] || exit 1
done

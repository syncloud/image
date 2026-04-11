#!/bin/sh
set -e

RELEASE=$1
REPO=$2
FILE_PATTERN=$3

echo "=== upload debug ==="
echo "release: $RELEASE"
echo "repo: $REPO"
echo "pattern: $FILE_PATTERN"

echo "--- checking token validity ---"
gh auth status 2>&1 || true

echo "--- ensuring release exists ---"
if gh release view "$RELEASE" --repo "$REPO" > /dev/null 2>&1; then
  echo "release $RELEASE already exists"
else
  echo "creating release $RELEASE"
  gh release create "$RELEASE" --repo "$REPO" --title "$RELEASE" --notes "$RELEASE"
fi

echo "--- release info ---"
gh api "repos/$REPO/releases/tags/$RELEASE" --jq '{id: .id, tag: .tag_name, name: .name, asset_count: (.assets | length), created_at: .created_at, assets: [.assets[].name]}' 2>&1 || true

for f in $FILE_PATTERN; do
  [ -f "$f" ] || continue
  name=$(basename "$f")

  echo "checking if $name exists in release $RELEASE ..."
  existing=$(gh api "repos/$REPO/releases/tags/$RELEASE" --jq ".assets[] | select(.name == \"$name\") | .name" 2>&1) || true
  echo "api result: '$existing'"

  if [ "$existing" = "$name" ]; then
    echo "$name already exists in release, skipping"
    continue
  fi

  local_size=$(stat -c%s "$f")
  uploaded=false
  for i in 1 2 3 4 5; do
    echo "attempt $i: uploading $name (${local_size} bytes)"
    timeout 600 gh release upload "$RELEASE" --repo "$REPO" --clobber "$f" && uploaded=true && break || sleep 30
  done
  [ "$uploaded" = true ] || exit 1
done

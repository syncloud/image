#!/bin/sh
set -e

RELEASE=$1
REPO=$2
NAME_PATTERN=$3

echo "release: $RELEASE"
echo "repo: $REPO"
echo "pattern: $NAME_PATTERN"

echo "fetching release assets ..."
assets=$(gh api "repos/$REPO/releases/tags/$RELEASE" --jq '.assets[].name' 2>&1) || true
echo "assets: $assets"

# Check if any asset matches the pattern
found=false
for asset in $assets; do
  case "$asset" in
    $NAME_PATTERN) echo "found: $asset"; found=true ;;
  esac
done

if [ "$found" = true ]; then
  echo "all assets already in release, skipping build"
  touch .skip
else
  echo "no matching asset found, build needed"
fi

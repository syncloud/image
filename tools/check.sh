#!/bin/sh
set -e

RELEASE=$1
REPO=$2
FILE_PATTERN=$3

echo "release: $RELEASE"
echo "repo: $REPO"
echo "pattern: $FILE_PATTERN"

for f in $FILE_PATTERN; do
  name=$(basename "$f")
  echo "checking if $name exists in release $RELEASE ..."
  existing=$(gh api "repos/$REPO/releases/tags/$RELEASE" --jq ".assets[] | select(.name == \"$name\") | .name" 2>&1) || true
  echo "api result: '$existing'"
  if [ "$existing" != "$name" ]; then
    echo "$name not found in release, build needed"
    exit 0
  fi
done

echo "all assets already in release, skipping build"
touch .skip

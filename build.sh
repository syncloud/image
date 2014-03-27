#!/bin/bash

if ! git diff --quiet HEAD; then
  echo "you have uncomitted files"
  exit 1
fi

BUILDDIR=scripts/
git rev-parse --short HEAD > $BUILDDIR/version
makeself --notemp $BUILDDIR syncloud_setup.sh "The ownCloud setup script" ./owncloud.sh

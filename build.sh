#!/bin/bash

BUILDDIR=scripts/
git rev-parse --short HEAD > $BUILDDIR/version
makeself --notemp $BUILDDIR syncloud_setup.sh "The ownCloud setup script" ./owncloud.sh

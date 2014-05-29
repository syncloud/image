#!/bin/bash

BUILDDIR=scripts/
git rev-parse --short HEAD > $BUILDDIR/version
makeself --notemp $BUILDDIR syncloud-setup.sh "The syncloud setup script" ./syncloud.sh

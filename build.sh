#!/bin/bash

BUILDDIR=scripts/

mkdir scripts

cp substitute.py $BUILDDIR
cp mounthdd.py $BUILDDIR

cp owncloud.sh $BUILDDIR
cp setmacaddr.sh $BUILDDIR

cp syncloud_boot.templ $BUILDDIR
cp setdataperm.templ $BUILDDIR
cp mounthdd.templ $BUILDDIR

makeself --notemp $BUILDDIR owncloud_setup.sh "The ownCloud setup script" ./owncloud.sh

rm -rf $BUILDDIR

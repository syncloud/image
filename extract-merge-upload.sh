#!/bin/bash -xe

ARCH=$(dpkg --print-architecture)
BOARD=$1
RELEASE=$2
BRANCH=$3

./extract/extract.sh $BOARD
./merge.sh $BOARD $ARCH $RELEASE
./upload.sh $RELEASE syncloud-$BOARD-$RELEASE.img.xz $BRANCH

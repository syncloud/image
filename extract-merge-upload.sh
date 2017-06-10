#!/bin/bash -xe

BOARD=$1
RELEASE=$2
ARCH=$3
BRANCH=$4

./extract/extract.sh $BOARD
./merge.sh $BOARD $ARCH $RELEASE
./upload.sh $RELEASE syncloud-$BOARD-$RELEASE.img.xz $BRANCH

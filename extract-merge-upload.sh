#!/bin/bash -xe

BOARD=$1
RELEASE=$2
ARCH=$3

./extract/extract.sh $BOARD
./merge.sh cubietruck $ARCH $RELEASE
./upload.sh $RELEASE syncloud-$BOARD-$RELEASE.img.xz

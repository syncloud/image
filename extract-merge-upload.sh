#!/bin/bash -xe

ARCH=$(dpkg --print-architecture)
BOARD=$1
RELEASE=$2
BRANCH=$3
IMAGE=syncloud-$BOARD-$RELEASE.img.xz

./extract/extract.sh $BOARD
./merge.sh $BOARD $ARCH $RELEASE
./upload.sh $RELEASE $IMAGE $BRANCH
rm -rf $IMAGE

ls -la
df -h
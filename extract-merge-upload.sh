#!/bin/bash -xe

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 board release installer arch"
    exit 1
fi


BOARD=$1
RELEASE=$2
INSTALLER=$3
ARCH=$4

IMAGE=syncloud-${BOARD}-${RELEASE}-${INSTALLER}.img.xz

./extract/extract.sh ${BOARD}
./merge.sh ${BOARD} ${ARCH} ${RELEASE} ${INSTALLER}
./upload.sh ${RELEASE} ${IMAGE}
rm -rf ${IMAGE}

ls -la
df -h
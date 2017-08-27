#!/bin/bash -xe

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 board release installer"
    exit 1
fi


ARCH=$(dpkg --print-architecture)
BOARD=$1
RELEASE=$2
INSTALLER=$3
IMAGE=syncloud-${BOARD}-${RELEASE}-${INSTALLER}.img.xz

./extract/extract.sh ${BOARD}
./merge.sh ${BOARD} ${ARCH} ${RELEASE} ${INSTALLER}
./upload.sh ${RELEASE} ${IMAGE}
rm -rf ${IMAGE}

ls -la
df -h
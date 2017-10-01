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
CHANNEL=rc
if [ "${DRONE_BRANCH}" == "stable" ]; then 
    CHANNEL=stable
fi

./extract/extract.sh ${BOARD} ${INSTALLER}
./merge.sh ${BOARD} ${ARCH} ${RELEASE} ${INSTALLER} ${CHANNEL}
./upload.sh ${RELEASE} ${IMAGE} ${CHANNEL}

rm -rf ${IMAGE}

ls -la
df -h
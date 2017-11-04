#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$#" -ne 6 ]; then
    echo "Usage: $0 board release installer arch base_image image"
    exit 1
fi

FREE_SPACE=$(df . | tail -1 | awk '{print $4}')
MIN_FREE_SPACE=5000000
if [ "$FREE_SPACE" -lt $MIN_FREE_SPACE ]; then
    echo "less then $MIN_FREE_SPACE left $FREE_SPACE"
    exit 1
fi

BOARD=$1
RELEASE=$2
INSTALLER=$3
ARCH=$4
BASE_IMAGE=$5
IMAGE=$6


CHANNEL=rc
if [ "${DRONE_BRANCH}" == "stable" ]; then 
    CHANNEL=stable
fi

function prepare {
    tools/extract.sh ${BOARD} ${INSTALLER} ${BASE_IMAGE}
    tools/merge.sh ${BOARD} ${ARCH} ${RELEASE} ${INSTALLER} ${CHANNEL} ${IMAGE}
}

attempts=5
attempt=0

set +e
prepare
while test $? -gt 0
do
  if [ ${attempt} -gt ${attempts} ]; then
    exit 1
  fi
  dmesg | tail -10
  sleep 3
  echo "===================================="
  echo "retrying building an image: $attempt"
  echo "===================================="
  attempt=$((attempt+1))
  prepare
done
set -e

tools/upload.sh ${RELEASE} ${IMAGE}.xz ${CHANNEL}

rm -rf ${IMAGE}.xz

ls -la
df -h
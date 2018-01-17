#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 board installer arch base_image image"
    exit 1
fi

FREE_SPACE=$(df . | tail -1 | awk '{print $4}')
MIN_FREE_SPACE=5000000
if [ "$FREE_SPACE" -lt $MIN_FREE_SPACE ]; then
    echo "less then $MIN_FREE_SPACE left $FREE_SPACE"
    exit 1
fi

BOARD=$1
INSTALLER=$2
ARCH=$3
BASE_IMAGE=$4
IMAGE=$5

CHANNEL=rc
if [ "${DRONE_BRANCH}" == "stable" ]; then 
    CHANNEL=stable
fi

function prepare {
    tools/extract.sh ${BOARD} ${INSTALLER} ${BASE_IMAGE}
    tools/merge.sh ${BOARD} ${ARCH} ${INSTALLER} ${CHANNEL} ${IMAGE}
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

tools/upload.sh ${IMAGE}.xz

rm -rf ${IMAGE}.xz

ls -la
df -h
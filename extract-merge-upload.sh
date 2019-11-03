#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -ne 4 ]]; then
    echo "Usage: $0 board arch base_image image"
    exit 1
fi

FREE_SPACE=$(df . | tail -1 | awk '{print $4}')
MIN_FREE_SPACE=5000000
if [[ "$FREE_SPACE" -lt ${MIN_FREE_SPACE} ]]; then
    echo "less then $MIN_FREE_SPACE left $FREE_SPACE"
    exit 1
fi

BOARD=$1
ARCH=$2
BASE_IMAGE=$3
IMAGE=$4

function build {
    tools/extract.sh ${BOARD} ${BASE_IMAGE}
    tools/merge.sh ${BOARD} ${ARCH} ${IMAGE}
}

attempts=0
attempt=0

set +e
build
while test $? -gt 0
do
  if [[ ${attempt} -gt ${attempts} ]]; then
    exit 1
  fi
  dmesg | tail -10
  sleep 3
  echo "===================================="
  echo "retrying building an image: $attempt"
  echo "===================================="
  attempt=$((attempt+1))
  build
done
set -e

ls -la
df -h

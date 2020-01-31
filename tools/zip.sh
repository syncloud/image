#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/functions.sh
if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 image mode"
    exit 1
fi
SYNCLOUD_IMAGE=$1
MODE=$2

echo "fdisk info:"
fdisk -l ${SYNCLOUD_IMAGE}

echo "zipping"
pxz -0 ${SYNCLOUD_IMAGE}

if [[ "$MODE" == "boot" ]]; then
  mv ${SYNCLOUD_IMAGE}.xz ${SYNCLOUD_IMAGE}_$MODE.xz
fi

ls -la *.xz

ls -la
df -h

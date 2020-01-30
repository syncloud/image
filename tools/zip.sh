#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
. functions.sh

SYNCLOUD_IMAGE=$1
MODE=$2

echo "fdisk info:"
fdisk -l ${SYNCLOUD_IMAGE}

echo "zipping"
pxz -0 ${SYNCLOUD_IMAGE}

if [[ "$MODE" == "" ]]; then

else
  cp ${SYNCLOUD_IMAGE}.xz ${SYNCLOUD_IMAGE}_$MODE.xz
fi

ls -la ${SYNCLOUD_IMAGE}.xz

ls -la
df -h

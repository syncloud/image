#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/functions.sh
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 image"
    exit 1
fi
SYNCLOUD_IMAGE=$1

echo "fdisk info:"
fdisk -l ${SYNCLOUD_IMAGE}

rm -f ${SYNCLOUD_IMAGE}.xz
xz ${SYNCLOUD_IMAGE}

ls -la *.xz

ls -la
df -h

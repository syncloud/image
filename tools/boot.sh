#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. ${DIR}/functions.sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 board image"
    exit 1
fi

SYNCLOUD_BOARD=$1
SYNCLOUD_IMAGE=$2

BOOT_ZIP=${SYNCLOUD_BOARD}.tar.gz
if [[ ! -f ${BOOT_ZIP} ]]; then
  echo "missing ${BOOT_ZIP}"
  exit 1
fi

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

SRC_ROOTFS=rootfs_${SYNCLOUD_BOARD}
DST_ROOTFS=dst_${SYNCLOUD_BOARD}/root

cleanup ${DST_ROOTFS} ${SRC_ROOTFS} ${SYNCLOUD_IMAGE}

echo "extracting boot"
rm -rf ${SYNCLOUD_BOARD}
tar xzf ${BOOT_ZIP}
ls -la
rm -rf ${BOOT_ZIP}

echo "copying boot"
cp ${SYNCLOUD_BOARD}/boot ${SYNCLOUD_IMAGE}

BOOT_BYTES=$(wc -c "${SYNCLOUD_IMAGE}" | cut -f 1 -d ' ')
BOOT_SECTORS=$(( ${BOOT_BYTES} / 512 ))
echo "boot sectors: ${BOOT_SECTORS}"

ROOTFS_SECTORS=$(( 3 * 1024 * 1024 * 2 ))
dd if=/dev/zero count=${ROOTFS_SECTORS} >> ${SYNCLOUD_IMAGE}
ROOTFS_START_SECTOR=$(( ${BOOT_SECTORS} + 1  ))
ROOTFS_END_SECTOR=$(( ${ROOTFS_START_SECTOR} + ${ROOTFS_SECTORS} - 2 ))
fdisk -l ${SYNCLOUD_IMAGE}

echo "creating second partition (${ROOTFS_START_SECTOR} - ${ROOTFS_END_SECTOR}) sectors"
echo "
n
p
2
${ROOTFS_START_SECTOR}
${ROOTFS_END_SECTOR}
w
q
" | fdisk ${SYNCLOUD_IMAGE}

sync

ls -la /dev/mapper/*

kpartx -l ${SYNCLOUD_IMAGE}
rm -rf dst_${SYNCLOUD_BOARD}
mkdir -p ${DST_ROOTFS}

ls -la /dev/mapper/*
sync

attempts=3
attempt=0
set +e
while true; do
    ( prepare_image ${SYNCLOUD_IMAGE} )
    if [[ $? -eq 0 ]]; then
        break
    fi
    cleanup ${DST_ROOTFS} ${SRC_ROOTFS} ${SYNCLOUD_IMAGE}
    if [[ ${attempt} -ge ${attempts} ]]; then
        exit 1
    fi
    dmesg | tail -10
    sleep 3
    echo "======================"
    echo "retrying image format: $attempt"
    echo "======================"
    attempt=$((attempt+1)) 
done
set -e

LOOP=$(cat loop.dev)
DEVICE_PART_1=/dev/mapper/${LOOP}p1
DEVICE_PART_2=/dev/mapper/${LOOP}p2
sync
UUID_FILE=${SYNCLOUD_BOARD}/root/uuid
if [[ -f "${UUID_FILE}" ]]; then
    change_uuid ${DEVICE_PART_1} clear
    change_uuid ${DEVICE_PART_2} clear
fi

cleanup ${DST_ROOTFS} ${SRC_ROOTFS} ${SYNCLOUD_IMAGE}

#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. ${DIR}/functions.sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 board image size"
    exit 1
fi

SYNCLOUD_BOARD=$1
SYNCLOUD_IMAGE=$2
ROOTFS_SIZE=$3

apt update
apt install -y gdisk wget xz-utils kpartx parted

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

SRC_ROOTFS=rootfs_${SYNCLOUD_BOARD}
DST_ROOTFS=dst_${SYNCLOUD_BOARD}/root

echo "copying boot"
cp ${SYNCLOUD_BOARD}/boot ${SYNCLOUD_IMAGE}

BOOT_BYTES=$(wc -c "${SYNCLOUD_IMAGE}" | cut -f 1 -d ' ')
BOOT_SECTORS=$(( ${BOOT_BYTES} / 512 ))
echo "boot sectors: ${BOOT_SECTORS}"
ROOTFS_SECTORS=$( numfmt --from=iec --to-unit=512 $ROOTFS_SIZE )
dd if=/dev/zero count=${ROOTFS_SECTORS} >> ${SYNCLOUD_IMAGE}
ROOTFS_START_SECTOR=$(( ${BOOT_SECTORS} + 1  ))
ROOTFS_END_SECTOR=$(( ${ROOTFS_START_SECTOR} + ${ROOTFS_SECTORS} - 100 ))
fdisk -l ${SYNCLOUD_IMAGE}
PTTYPE=$(<${SYNCLOUD_BOARD}/root/pttype)

echo "creating second partition (${ROOTFS_START_SECTOR} - ${ROOTFS_END_SECTOR}) sectors"

if [[ $PTTYPE == "gpt" ]]; then
  LOOP=$(losetup -f --show ${SYNCLOUD_IMAGE})
  echo "
r
d
w
Y
Y
" | gdisk $LOOP

  sgdisk -n 2:${ROOTFS_START_SECTOR}:${ROOTFS_END_SECTOR} -p $LOOP
  partprobe $LOOP
  sync
  kpartx -d ${SYNCLOUD_IMAGE} || true
  losetup -d $LOOP || true

else

  echo "
n
p
2
${ROOTFS_START_SECTOR}
${ROOTFS_END_SECTOR}
w
q
" | fdisk ${SYNCLOUD_IMAGE}

fi

sync

ls -la /dev/mapper/*

kpartx -d ${SYNCLOUD_IMAGE} || true
rm -rf dst_${SYNCLOUD_BOARD}
mkdir -p ${DST_ROOTFS}

ls -la /dev/mapper/*
sync

prepare_image ${SYNCLOUD_IMAGE}
LOOP=$(cat loop.dev)
DEVICE_PART_1=/dev/mapper/${LOOP}p1
DEVICE_PART_2=/dev/mapper/${LOOP}p2
sync
if [[ -f "${SYNCLOUD_BOARD}/root/uuid" ]]; then
  if [[ -f "${SYNCLOUD_BOARD}/root/single_partition" ]]; then
    change_uuid ${DEVICE_PART_1} clear
  fi
  change_uuid ${DEVICE_PART_2} clear
fi
kpartx -d ${SYNCLOUD_IMAGE}
dmsetup remove -f /dev/mapper/${LOOP}p1 || true
dmsetup remove -f /dev/mapper/${LOOP}p2 || true
losetup -d /dev/${LOOP} || true
losetup | grep img || true

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
apt install -y gdisk wget xz-utils kpartx parted fdisk

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
COUNT_TO_ROOTFS=${ROOTFS_SECTORS}
dd if=/dev/zero bs=512 count=${COUNT_TO_ROOTFS} >> ${SYNCLOUD_IMAGE}
ROOTFS_START_SECTOR=$(( ${BOOT_SECTORS} + 1  ))
ROOTFS_END_SECTOR=$(( ${ROOTFS_START_SECTOR} + ${ROOTFS_SECTORS} - 100 ))
fdisk -l ${SYNCLOUD_IMAGE}
PTTYPE=$(<${SYNCLOUD_BOARD}/root/pttype)
PARTITIONS=$(<${SYNCLOUD_BOARD}/root/partitions)


echo "creating ${PARTITIONS} partition (${ROOTFS_START_SECTOR} - ${ROOTFS_END_SECTOR}) sectors"

if [[ $PTTYPE == "gpt" ]]; then
  LOOP=$(losetup -f --show ${SYNCLOUD_IMAGE})
  echo "
r
d
w
Y
Y
" | gdisk $LOOP

  USABLE_SECTORS=$(sgdisk $LOOP -E 2>/dev/null)
  if [[ ${ROOTFS_END_SECTOR} -gt ${USABLE_SECTORS} ]]; then
     echo "fixing the end of rootfs sectors from ${ROOTFS_END_SECTOR} to ${USABLE_SECTORS}"
     ROOTFS_END_SECTOR=$USABLE_SECTORS
  fi
  sgdisk -n ${PARTITIONS}:${ROOTFS_START_SECTOR}:${ROOTFS_END_SECTOR} -p $LOOP
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


LAST_SECTOR=$(fdisk -l "$SYNCLOUD_IMAGE" \
  | tr '*' ' ' \
  | awk -v img="$(basename "$SYNCLOUD_IMAGE")" '$1 ~ img {print $3}' \
  | sort -n | tail -1)
LAST_PARTITION_NUMBER=$(fdisk -l $SYNCLOUD_IMAGE | grep $LAST_SECTOR | grep -oP '(?<=^'$SYNCLOUD_IMAGE')\d+')

prepare_image ${SYNCLOUD_IMAGE} $LAST_PARTITION_NUMBER
cat kpartx.out
LOOP=$(cat loop.dev)
LAST_PART=/dev/mapper/${LOOP}p${LAST_PARTITION_NUMBER}
sync
if [[ -f "${SYNCLOUD_BOARD}/root/uuid" ]]; then
  change_uuid ${LAST_PART} clear
fi
losetup -l

kpartx -d ${SYNCLOUD_IMAGE}
dmsetup remove -f /dev/mapper/${LOOP}p1 || true
dmsetup remove -f /dev/mapper/${LOOP}p2 || true
dmsetup remove -f /dev/mapper/${LOOP}p3 || true
losetup -d /dev/${LOOP} || true
losetup | grep img || true

#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$1" == "" ]; then
    echo "Usage: $0 base_image"
    exit 1
fi

BOARD_RAW=$1
BOARD=$( echo ${BOARD_RAW} | sed 's/%2B/+/g' )
BASE_IMAGE=${BOARD}.img
BASE_IMAGE_ZIP=${BASE_IMAGE}.7z
BOOT_URL=https://s3-us-west-2.amazonaws.com/syncloud-distributives
PARTED_SECTOR_UNIT=s
DD_SECTOR_UNIT=b
OUTPUT=${BOARD}

if [ ! -f ${BASE_IMAGE} ]; then
  echo "getting boot"
  wget ${BOOT_URL}/${BOARD_RAW}.img.7z
  p7zip -d ${BASE_IMAGE_ZIP}
else
  echo "$BASE_IMAGE is here"
fi

BOOT_PARTITION_END_SECTOR=$(parted -sm ${BASE_IMAGE} unit ${PARTED_SECTOR_UNIT} print | grep "^1" | cut -d ':' -f3 | cut -d 's' -f1)
rm -rf ${OUTPUT}
mkdir ${OUTPUT}

echo "extracting boot partition with boot loader"
dd if=${BASE_IMAGE} of=${OUTPUT}/boot bs=1${DD_SECTOR_UNIT} count=$(( ${BOOT_PARTITION_END_SECTOR} ))

echo "extracting kernel modules and firmware from rootfs"

rm -rf rootfs
mkdir -p rootfs
kpartx -a ${BASE_IMAGE}
LOOP=$(kpartx -l ${BASE_IMAGE} | head -1 | cut -d ' ' -f1 | cut -c1-5)
mount /dev/mapper/${LOOP}p2 rootfs

mkdir ${OUTPUT}/root
cp -r rootfs/lib/firmware ${OUTPUT}/root/firmware
cp -r rootfs/lib/modules ${OUTPUT}/root/modules
sync

umount rootfs
kpartx -d ${BASE_IMAGE}

rm -rf ${OUTPUT}.tar.gz
tar czf ${OUTPUT}.tar.gz ${OUTPUT}

echo "result: $OUTPUT.tar.gz"

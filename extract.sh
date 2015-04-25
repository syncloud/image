#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$1" == "" ]; then
    echo "Usage: $0 base.img"
    exit 1
fi

BASE_IMAGE=$1

PARTED_SECTOR_UNIT=s
DD_SECTOR_UNIT=b
OUTPUT=$( echo ${BASE_IMAGE} | rev | cut -c5- | rev )

BOOT_PARTITION_END_SECTOR=$(parted -sm ${BASE_IMAGE} unit ${PARTED_SECTOR_UNIT} print | grep "^1" | cut -d ':' -f3 | cut -d 's' -f1)
rm -rf ${OUTPUT}
mkdir ${OUTPUT}

echo "extracting boot partition with boot loader"
dd if=${BASE_IMAGE} of=${OUTPUT}/boot bs=1${DD_SECTOR_UNIT} count=$(( ${BOOT_PARTITION_END_SECTOR} ))

echo "extracting kernel modules and firmware from rootfs"

rm -rf extract_rootfs
mkdir -p extract_rootfs
kpartx -a ${BASE_IMAGE}
LOOP=$(kpartx -l ${BASE_IMAGE} | head -1 | cut -d ' ' -f1 | cut -c1-5)
mount /dev/mapper/${LOOP}p2 extract_rootfs

mkdir -p ${OUTPUT}/root
mkdir ${OUTPUT}/root/lib
#cp -rp extract_rootfs/* ${OUTPUT}/root/
cp -r extract_rootfs/lib/firmware ${OUTPUT}/root/lib/firmware
cp -r extract_rootfs/lib/modules ${OUTPUT}/root/lib/modules
sync

umount extract_rootfs
kpartx -d ${BASE_IMAGE}

rm -rf ${OUTPUT}.tar.gz
tar czf ${OUTPUT}.tar.gz ${OUTPUT}

echo "result: $OUTPUT.tar.gz"

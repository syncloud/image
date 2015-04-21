#!/bin/bash

if [ "$1" == "" ]; then
    echo "Usage: $0 base_image"
    exit 1
fi

BASE_IMAGE=$1
PARTED_SECTOR_UNIT=s
DD_SECTOR_UNIT=b
OUTPUT=$(echo ${BASE_IMAGE} | cut -d'.' -f1)
OUTPUT_BOOT_FILE=boot
OUTPUT_KERNEL_FILES=rootfs

BOOT_PARTITION_END=$(parted -sm ${BASE_IMAGE} unit ${PARTED_SECTOR_UNIT} print | grep "^1" | cut -d ':' -f3 | cut -d 's' -f1)
rm -rf ${OUTPUT}
mkdir ${OUTPUT}

echo "extracting boot partition with boot loader"
rm -rf ${OUTPUT_BOOT_FILE}
dd if=${BASE_IMAGE} of=${OUTPUT}/${OUTPUT_BOOT_FILE} bs=1${DD_SECTOR_UNIT} count=${BOOT_PARTITION_END}

echo "extracting kernel modules and firmware from rootfs"

rm -rf rootfs
mkdir -p rootfs
kpartx -a ${BASE_IMAGE}
LOOP=$(kpartx -l ${BASE_IMAGE} | head -1 | cut -d ' ' -f1 | cut -c1-5)
mount /dev/mapper/${LOOP}p2 rootfs

mkdir ${OUTPUT}/${OUTPUT_KERNEL_FILES}
cp -r rootfs/lib/firmware ${OUTPUT}/${OUTPUT_KERNEL_FILES}/firmware
cp -r rootfs/lib/modules ${OUTPUT}/${OUTPUT_KERNEL_FILES}/modules
sync

umount rootfs
kpartx -d ${BASE_IMAGE}

rm -rf ${OUTPUT}.tar.gz
tar czf ${OUTPUT}.tar.gz ${OUTPUT}

echo "result: $OUTPUT.tar.gz"

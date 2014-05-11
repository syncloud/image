#!/bin/bash

if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root" 1>&2
   exit 1
fi

e2fsck -f -y -v /dev/mmcblk0p2
resize2fs /dev/mmcblk0p2 3000M
dd if=/dev/mmcblk0 of=./raspberrypi.img bs=1M count=3100
xz -z raspberrypi.img

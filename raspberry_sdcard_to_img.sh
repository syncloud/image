#!/bin/bash

e2fsck -f -y -v /dev/mmcblk0p2
resize2fs /dev/mmcblk0p2 3000M
dd if=/dev/mmcblk0 of=./raspberrypi.img bs=1M count=3100
xz -z raspberrypi.img

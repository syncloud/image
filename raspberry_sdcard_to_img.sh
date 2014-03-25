#!/bin/bash

e2fsck -f -y -v /dev/mmcblk0p2
resize2fs /dev/mmcblk0p2 2700M
dd if=/dev/mmcblk0 of=./raspberrypi.img bs=1M count=2800
xz -z raspberrypi.img

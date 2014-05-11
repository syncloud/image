#!/bin/bash

e2fsck -f -y -v /dev/mmcblk0p2
resize2fs /dev/mmcblk0p2 1300M
dd if=/dev/mmcblk0 of=./beagle.img bs=1M count=1500
xz -z beagle.img

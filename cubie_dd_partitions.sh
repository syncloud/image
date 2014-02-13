#!/bin/bash

dd if=/dev/nandc of=/data/rootfs.fex.iso
sync
dd if=/dev/nandd of=/data/libs.fex.iso
sync
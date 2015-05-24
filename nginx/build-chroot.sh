#!/bin/bash

if [ ! -f "rootfs.tar.gz" ]; then
    echo "rootfs is not ready, run 'sudo ./bootstrap.sh'"
    exit 1
elae
    echo "rootfs.tar.gz is here"
fi

tar xzf rootfs.tar.gz
cp build.sh rootfs/root
chroot rootfs root/build.sh
mv rootfs/root/nginx*.tar.gz .
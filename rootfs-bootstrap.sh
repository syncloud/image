#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 debian_repo_url"
    exit 1
fi

DEB_REPO=$1

apt-get -y install debootstrap

rm -rf rootfs
rm -rf rootfs.tar.gz

debootstrap --foreign --no-check-gpg --include=ca-certificates --arch=armhf wheezy rootfs ${DEB_REPO}
cp $(which qemu-arm-static) rootfs/usr/bin
chroot rootfs /debootstrap/debootstrap --second-stage --verbose

tar czf rootfs.tar.gz rootfs
#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 debian_repo_url"
    exit 1
fi

DEB_REPO=$1
export DEBIAN_FRONTEND=noninteractive

apt-get -y install debootstrap

function cleanup {
    umount rootfs/sys
}

cleanup

rm -rf rootfs
rm -rf rootfs.tar.gz

qemu-debootstrap --no-check-gpg --include=ca-certificates --arch=armhf wheezy rootfs ${DEB_REPO}

cleanup

tar czf rootfs.tar.gz rootfs
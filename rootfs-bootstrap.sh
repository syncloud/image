#!/bin/bash

DEB_REPO=http://archive.raspbian.com/raspbian

rm -rf rootfs
rm -rf rootfs.tar.gz

debootstrap --foreign --no-check-gpg --include=ca-certificates --arch=armhf wheezy rootfs ${DEB_REPO}
chroot rootfs /debootstrap/debootstrap --second-stage --verbose

tar czf rootfs.tar.gz rootfs
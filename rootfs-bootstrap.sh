#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 debian_repo_url"
    exit 1
fi

DEB_REPO=$1
export DEBIAN_FRONTEND=noninteractive

apt-get -y install debootstrap

function cleanup {
    echo "cleaning"
    umount rootfs/sys
    umount rootfs/dev/pts
    umount rootfs/proc
}

cleanup

rm -rf rootfs
rm -rf rootfs.tar.gz

qemu-debootstrap --no-check-gpg --include=ca-certificates --arch=armhf wheezy rootfs ${DEB_REPO}

chroot rootfs /bin/bash -c "echo \"root:syncloud\" | chpasswd"
echo "nameserver 8.8.8.8" > rootfs/run/resolvconf/resolv.conf

chroot rootfs /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot rootfs /bin/bash -c "mount -t proc proc /proc"

chroot rootfs /bin/bash -c "apt-get update"
chroot rootfs /bin/bash -c "apt-get -y dist-upgrade"
chroot rootfs /bin/bash -c "apt-get -y install locales"
chroot rootfs /bin/bash -c "locale-gen en_US en_US.UTF-8"
echo "deb http://ftp.us.debian.org/debian wheezy main contrib non-free" rootfs/etc/apt/sources.list
echo "deb http://security.debian.org wheezy/updates main contrib non-free" rootfs/etc/apt/sources.list
chroot rootfs /bin/bash -c "apt-get update"
chroot rootfs /bin/bash -c "apt-get -y install openssh-server"
sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" rootfs/etc/ssh/sshd_config

cleanup

tar czf rootfs.tar.gz rootfs
#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 distro"
    exit 1
fi

DISTRO=$1

if [[ ${DISTRO} == "rasbian" ]]; then
    REPO=http://archive.raspbian.com/raspbian
    KEY=http://archive.raspbian.org/raspbian.public.key
elif [[ ${DISTRO} == "debian" ]]; then
    REPO=http://http.debian.net/debian
    KEY=https://ftp-master.debian.org/keys/archive-key-7.0.asc
else
    echo "${DISTRO} is not supported"
    exit 1
fi

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
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

qemu-debootstrap --no-check-gpg --include=ca-certificates --arch=armhf wheezy rootfs ${REPO}

echo "export LC_ALL=C" >> rootfs/root/.bashrc
chroot rootfs wget ${KEY} -O archive.key
chroot rootfs apt-key add archive.key

chroot rootfs /bin/bash -c "echo \"root:syncloud\" | chpasswd"
#echo "nameserver 8.8.8.8" > rootfs/run/resolvconf/resolv.conf

chroot rootfs /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot rootfs /bin/bash -c "mount -t proc proc /proc"

cp ${DISTRO}.sources.list rootfs/etc/apt/sources.list

chroot rootfs /bin/bash -c "apt-get update"
chroot rootfs /bin/bash -c "apt-get -y install locales"
chroot rootfs /bin/bash -c "locale-gen en_US en_US.UTF-8"
chroot rootfs /bin/bash -c "apt-get -y dist-upgrade"

chroot rootfs /bin/bash -c "apt-get -y install openssh-server"
sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" rootfs/etc/ssh/sshd_config

cleanup

tar czf rootfs.tar.gz rootfs
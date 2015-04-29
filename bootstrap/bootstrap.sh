#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 distro"
    exit 1
fi

DISTRO=$1

if [[ ${DISTRO} == "raspbian" ]]; then
    REPO=http://archive.raspbian.com/raspbian
    KEY=http://archive.raspbian.org/raspbian.public.key
elif [[ ${DISTRO} == "debian" ]]; then
    REPO=http://http.debian.net/debian
    KEY=https://ftp-master.debian.org/keys/archive-key-7.0.asc
else
    echo "${DISTRO} is not supported"
    exit 1
fi

echo "Open file limit: $(ulimit -n)"

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

apt-get -y install debootstrap

function cleanup {

    echo "open files"
    lsof | grep rootfs

    echo "chroot processes"
    ps auxfw | grep qemu-arm-static
    pkill -f qemu-arm-static

    echo "cleaning"
    umount rootfs/sys
    umount rootfs/dev/pts
    umount rootfs/proc
#    umount rootfs/var/run/dbus/
}

cleanup

rm -rf rootfs
rm -rf rootfs.tar.gz

qemu-debootstrap --no-check-gpg --include=ca-certificates,locales --arch=armhf wheezy rootfs ${REPO}

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' rootfs/etc/locale.gen
chroot rootfs /bin/bash -c "locale-gen en_US en_US.UTF-8"

chroot rootfs wget ${KEY} -O archive.key
chroot rootfs apt-key add archive.key

chroot rootfs /bin/bash -c "echo \"root:syncloud\" | chpasswd"
#echo "nameserver 8.8.8.8" > rootfs/run/resolvconf/resolv.conf

#mount -o bind /dev rootfs/dev
#mount -o bind /proc rootfs/proc
#mount -o bind /sys rootfs/sys

chroot rootfs /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot rootfs /bin/bash -c "mount -t proc proc /proc"
#mount --bind /var/run/dbus/ rootfs/var/run/dbus/

cp ${DISTRO}.sources.list rootfs/etc/apt/sources.list

chroot rootfs apt-get update
chroot rootfs apt-get -y dist-upgrade
chroot rootfs apt-get -y install openssh-server python-dev gcc wget less bootlogd systemd
sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" rootfs/etc/ssh/sshd_config
yes 'Yes, do as I say!' 2>/dev/null | chroot rootfs apt-get install -y --force-yes systemd-sysv

cleanup

tar czf rootfs.tar.gz rootfs
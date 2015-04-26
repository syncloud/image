#!/bin/bash

START_TIME=$(date +"%s")

export DEBIAN_FRONTEND=noninteractive

BASE_ROOTFS_ZIP=rootfs.tar.gz

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function cleanup {
    echo "cleanup"
    umount rootfs/dev/pts
    umount rootfs/proc
}

echo "installing dependencies"
sudo apt-get -y install p7zip qemu-user-static

if [[ $? != 0 ]]; then
  echo "unable to install dependencies"
  exit1
fi

if [ ! -f ${BASE_ROOTFS_ZIP} ]; then
  echo "${BASE_ROOTFS_ZIP} not found"
fi

cleanup

rm -rf rootfs
mkdir -p rootfs

echo "extracting rootfs"

tar xzf ${BASE_ROOTFS_ZIP}

if [[ $(uname -m) != *"arm"* ]]; then
    echo "enabling arm binary support"
    cp $(which qemu-arm-static) rootfs/usr/bin
fi

echo "disable service restart"
cp disable-service-restart.sh rootfs/root
chroot rootfs /root/disable-service-restart.sh

echo "configuring rootfs"
chroot rootfs /bin/bash -c "locale-gen en_US en_US.UTF-8"
chroot rootfs /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot rootfs /bin/bash -c "mount -t proc proc /proc"

chroot rootfs /bin/bash -c "echo \"root:syncloud\" | chpasswd"
echo "nameserver 8.8.8.8" > rootfs/run/resolvconf/resolv.conf
sed -i '/^#.*deb .*universe/s/^# *//' rootfs/etc/apt/sources.list

echo "installing ssh server"
chroot rootfs /bin/bash -c "apt-get update"
chroot rootfs /bin/bash -c "apt-get -y dist-upgrade"
chroot rootfs /bin/bash -c "apt-get -y install openssh-server"
sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" rootfs/etc/ssh/sshd_config

cp RELEASE rootfs/root
cp syncloud.sh rootfs/root
chroot rootfs /bin/bash -c "/root/syncloud.sh"

cleanup

echo "enable restart"
cp enable-service-restart.sh rootfs/root
chroot rootfs /root/enable-service-restart.sh

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))

echo "Build time: $(($BUILD_TIME / 60)) min"

#!/bin/bash

START_TIME=$(date +"%s")

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

BASE_ROOTFS_ZIP=rootfs.tar.gz

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function cleanup {
    echo "cleanup"
    if mount | grep rootfs/dev/pts; then
        umount rootfs/dev/pts
    fi
    if mount | grep rootfs/proc; then
        umount rootfs/proc
    fi
}

printenv

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

echo "setting version ${build.number}"
echo ${build.number} > rootfs/version

echo "disable service restart"
cp disable-service-restart.sh rootfs/root
chroot rootfs /root/disable-service-restart.sh

echo "configuring rootfs"
chroot rootfs /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot rootfs /bin/bash -c "mount -t proc proc /proc"

echo "upgrade rootfs"
chroot rootfs /bin/bash -c "apt-get update"
chroot rootfs /bin/bash -c "apt-get -y dist-upgrade"

cp -R info rootfs/root/
cp syncloud.sh rootfs/root
chroot rootfs /bin/bash -c "/root/syncloud.sh"

if [[ $? != 0 ]]; then
  echo "syncloud build failed"
  exit 1
fi

cleanup

echo "enable restart"
cp enable-service-restart.sh rootfs/root
chroot rootfs /root/enable-service-restart.sh

tar czf syncloud-rootfs.tar.gz rootfs

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))

echo "Build time: $(($BUILD_TIME / 60)) min"
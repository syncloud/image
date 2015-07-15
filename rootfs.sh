#!/bin/bash

START_TIME=$(date +"%s")

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 distro [arch]"
    exit 1
fi
DISTRO=$1

ARCH=$(dpkg-architecture -q DEB_HOST_GNU_CPU)
if [ ! -z "$2" ]; then
    ARCH=$2
fi

BASE_ROOTFS_ZIP=rootfs-${ARCH}.tar.gz
ROOTFS=/tmp/rootfs

if [ ! -f ${BASE_ROOTFS_ZIP} ]; then
  wget http://build.syncloud.org:8111/guestAuth/repository/download/${DISTRO}_rootfs_${ARCH}/lastSuccessful/rootfs.tar.gz\
  -O ${BASE_ROOTFS_ZIP} --progress dot:giga
else
  echo "skipping rootfs"
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function cleanup {
    mount | grep rootfs
    mount | grep rootfs | awk '{print "umounting "$1; system("umount "$3)}'
    mount | grep rootfs

    echo "killing chroot services"
    lsof 2>&1 | grep rootfs | grep -v java | grep -v docker | grep -v rootfs.sh | awk '{print $1" "$2}' | sort | uniq

    lsof 2>&1 | grep rootfs | grep -v java | grep -v docker | grep -v rootfs.sh | awk '{print $2}' | sort | uniq | xargs kill -9

    lsof 2>&1 | grep rootfs
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

rm -rf ${ROOTFS}
mkdir -p ${ROOTFS}

echo "extracting rootfs"

tar xzf ${BASE_ROOTFS_ZIP} -C ${ROOTFS}

echo "enabling arm binary support"
cp $(which qemu-arm-static) ${ROOTFS}/usr/bin

echo "setting version ${BUILD_NUMBER}"
echo ${BUILD_NUMBER} > ${ROOTFS}/version

echo "disable service restart"
cp disable-service-restart.sh ${ROOTFS}/root
chroot ${ROOTFS} /root/disable-service-restart.sh

echo "configuring rootfs"
chroot ${ROOTFS} /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot ${ROOTFS} /bin/bash -c "mount -t proc proc /proc"

cp -R info ${ROOTFS}/root/
cp syncloud.sh ${ROOTFS}/root
chroot ${ROOTFS} /bin/bash -c "/root/syncloud.sh"

if [[ $? != 0 ]]; then
  echo "syncloud build failed"
  exit 1
fi

cleanup

echo "enable restart"
cp enable-service-restart.sh ${ROOTFS}/root
chroot ${ROOTFS} /root/enable-service-restart.sh

rm -rf build
mkdir build
echo "zipping"
tar czf build/rootfs.tar.gz -C ${ROOTFS} .

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))

echo "rootfs: build/rootfs.tar.gz"

echo "Build time: $(($BUILD_TIME / 60)) min"
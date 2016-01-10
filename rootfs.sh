#!/bin/bash

START_TIME=$(date +"%s")

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 distro arch sam_version release"
    exit 1
fi
DISTRO=$1
ARCH=$2
SAM_VERSION=$3
RELEASE=$4

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
sudo apt-get -y install p7zip qemu-user-static lsof

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

echo "installing sam ${SAM_VERSION}-${ARCH}"
SAM=sam-${SAM_VERSION}-${ARCH}.tar.gz
wget http://apps.syncloud.org/apps/${SAM} --progress=dot:giga -O ${SAM}
tar xzf ${SAM} -C ${ROOTFS}/opt/app

cp syncloud.sh ${ROOTFS}/root
chroot ${ROOTFS} /bin/bash -c "/root/syncloud.sh ${RELEASE}"

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

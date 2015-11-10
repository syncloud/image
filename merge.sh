#!/bin/bash

START_TIME=$(date +"%s")

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 board distro"
    exit 1
fi
SYNCLOUD_BOARD=$1
DISTRO=$2
echo "========== ${SYNCLOUD_BOARD} =========="

if [ ! -f "rootfs.tar.gz" ]; then
    wget http://build.syncloud.org:8111/guestAuth/repository/download/${DISTRO}_rootfs_syncloud_armv7l/lastSuccessful/rootfs.tar.gz\
  -O rootfs.tar.gz --progress dot:giga
else
    echo "rootfs.tar.gz is here"
fi

BOOT_ZIP=${SYNCLOUD_BOARD}.tar.gz
if [ ! -f ${BOOT_ZIP} ]; then
  wget http://build.syncloud.org:8111/guestAuth/repository/download/boot_extract/lastSuccessful/${BOOT_ZIP}\
  -O ${BOOT_ZIP} --progress dot:giga
else
  echo "$BOOT_ZIP is here"
fi

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

RESIZE_PARTITION_ON_FIRST_BOOT=true
SYNCLOUD_IMAGE=syncloud-${SYNCLOUD_BOARD}.img
SRC_ROOTFS=rootfs
DST_ROOTFS=dst/root

function cleanup {
    echo "cleanup"
    mount | grep ${DST_ROOTFS}
    mount | grep ${DST_ROOTFS} | awk '{print "umounting "$1; system("umount "$3)}'
    mount | grep ${DST_ROOTFS}
    rm -rf ${SRC_ROOTFS}
    losetup -a
    kpartx -v ${SYNCLOUD_IMAGE}
    echo "removing loop devices"
    kpartx -d ${SYNCLOUD_IMAGE}
}

echo "installing dependencies"
apt-get -y install dosfstools kpartx p7zip

cleanup

mkdir ${SRC_ROOTFS}
tar xzf rootfs.tar.gz -C${SRC_ROOTFS}

echo "extracting boot"
rm -rf ${SYNCLOUD_BOARD}
tar xzf ${BOOT_ZIP}

echo "copying boot"
cp ${SYNCLOUD_BOARD}/boot ${SYNCLOUD_IMAGE}
BOOT_BYTES=$(wc -c "${SYNCLOUD_IMAGE}" | cut -f 1 -d ' ')
BOOT_SECTORS=$(( ${BOOT_BYTES} / 512 ))
echo "boot sectors: ${BOOT_SECTORS}"

DD_CHUNK_SIZE_MB=10
DD_CHUNK_COUNT=200
ROOTFS_SIZE_BYTES=$(( ${DD_CHUNK_SIZE_MB} * 1024 * 1024 * ${DD_CHUNK_COUNT} ))
echo "appending $(( ${ROOTFS_SIZE_BYTES} / 1024 / 1024 )) MB"
dd if=/dev/zero bs=${DD_CHUNK_SIZE_MB}M count=${DD_CHUNK_COUNT} >> ${SYNCLOUD_IMAGE}
ROOTFS_START_SECTOR=$(( ${BOOT_SECTORS} + 1  ))
ROOTFS_SECTORS=$(( ${ROOTFS_SIZE_BYTES} / 512 ))
ROOTFS_END_SECTOR=$(( ${ROOTFS_START_SECTOR} + ${ROOTFS_SECTORS} - 2 ))
echo "extending defining second partition (${ROOTFS_START_SECTOR} - ${ROOTFS_END_SECTOR}) sectors"
echo "
p
d
2
p
n
p
2
${ROOTFS_START_SECTOR}
${ROOTFS_END_SECTOR}
p
w
q
" | fdisk ${SYNCLOUD_IMAGE}

kpartx -a ${SYNCLOUD_IMAGE}

kpartx -l ${SYNCLOUD_IMAGE}

LOOP=$(kpartx -l ${SYNCLOUD_IMAGE} | head -1 | cut -d ' ' -f1 | cut -c1-5)
rm -rf dst
mkdir -p ${DST_ROOTFS}

mkfs.ext4 /dev/mapper/${LOOP}p2
mount /dev/mapper/${LOOP}p2 ${DST_ROOTFS}

echo "copying rootfs"
cp -rp ${SRC_ROOTFS}/* ${DST_ROOTFS}/
cp -rp ${SYNCLOUD_BOARD}/root/* ${DST_ROOTFS}/

echo "setting resize on boot flag"
if [ "$RESIZE_PARTITION_ON_FIRST_BOOT" = true ] ; then
    touch ${DST_ROOTFS}/var/lib/resize_partition_flag
fi

echo "setting hostname"
echo ${SYNCLOUD_BOARD} > ${DST_ROOTFS}/etc/hostname

sync

cleanup

ls -la ${DST_ROOTFS}

echo "zipping"
xz -0 ${SYNCLOUD_IMAGE}

ls -la ${SYNCLOUD_IMAGE}

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))
echo "image: ${SYNCLOUD_IMAGE}"
echo "Build time: $(($BUILD_TIME / 60)) min"

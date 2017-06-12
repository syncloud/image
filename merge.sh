#!/bin/bash -xe

START_TIME=$(date +"%s")

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 board arch release"
    exit 1
fi

SYNCLOUD_BOARD=$1
ARCH=$2
RELEASE=$3
ROOTFS_FILE=syncloud-rootfs-${ARCH}.tar.gz
echo "==== ${SYNCLOUD_BOARD}, ${ARCH} ===="

if [ ! -f $ROOTFS_FILE ]; then
    wget http://artifact.syncloud.org/image/syncloud-rootfs-${ARCH}.tar.gz --progress dot:giga
else
    echo "$ROOTFS_FILE is here"
fi

BOOT_ZIP=boot_${SYNCLOUD_BOARD}/${SYNCLOUD_BOARD}.tar.gz
if [ ! -f ${BOOT_ZIP} ]; then
  echo "missing ${BOOT_ZIP}"
  exit 1
fi

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

RESIZE_PARTITION_ON_FIRST_BOOT=true
SYNCLOUD_IMAGE=syncloud-${SYNCLOUD_BOARD}-$RELEASE.img
SRC_ROOTFS=rootfs_${SYNCLOUD_BOARD}
DST_ROOTFS=dst_${SYNCLOUD_BOARD}/root

SRC_FILES=files/${SYNCLOUD_BOARD}

function cleanup {
    echo "===== cleanup ====="

    ls -la /dev/mapper/*
    mount | grep ${DST_ROOTFS} || true
    mount | grep ${DST_ROOTFS} | awk '{print "umounting "$1; system("umount "$3)}' || true
    mount | grep ${DST_ROOTFS} || true
    rm -rf ${SRC_ROOTFS}
    losetup -a
    kpartx -v ${SYNCLOUD_IMAGE} || true
    echo "removing loop devices"
    kpartx -d ${SYNCLOUD_IMAGE} || true
}

cleanup

mkdir ${SRC_ROOTFS}
tar xzf $ROOTFS_FILE -C${SRC_ROOTFS}

echo "extracting boot"
rm -rf ${SYNCLOUD_BOARD}
tar xzf ${BOOT_ZIP}

echo "copying boot"
cp ${SYNCLOUD_BOARD}/boot ${SYNCLOUD_IMAGE}
BOOT_BYTES=$(wc -c "${SYNCLOUD_IMAGE}" | cut -f 1 -d ' ')
BOOT_SECTORS=$(( ${BOOT_BYTES} / 512 ))
echo "boot sectors: ${BOOT_SECTORS}"

DD_CHUNK_SIZE_MB=10
DD_CHUNK_COUNT=300
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

ls -la /dev/mapper/*

kpartx -l ${SYNCLOUD_IMAGE}
kpartx -asv ${SYNCLOUD_IMAGE}

LOOP=$(kpartx -l ${SYNCLOUD_IMAGE} | head -1 | cut -d ' ' -f1 | cut -c1-5)
rm -rf dst_${SYNCLOUD_BOARD}
mkdir -p ${DST_ROOTFS}

ls -la /dev/mapper/*

mkfs.ext4 /dev/mapper/${LOOP}p2
UUID_FILE=${SYNCLOUD_BOARD}/root/uuid
if [ -f "${UUID_FILE}" ]; then
    UUID=$(<${UUID_FILE})
    echo "setting uuid: $UUID"
    tune2fs /dev/mapper/${LOOP}p2 -U $UUID
fi

mount /dev/mapper/${LOOP}p2 ${DST_ROOTFS}

echo "copying rootfs"
cp -rp ${SRC_ROOTFS}/* ${DST_ROOTFS}/
cp -rp ${SYNCLOUD_BOARD}/root/* ${DST_ROOTFS}/

echo "copying files"
cp -rp ${SRC_FILES}/* ${DST_ROOTFS}/

if [ -f ${DST_ROOTFS}/etc/fstab.vbox ]; then
  mv ${DST_ROOTFS}/etc/fstab.vbox ${DST_ROOTFS}/etc/fstab
fi

echo "setting resize on boot flag"
if [ "$RESIZE_PARTITION_ON_FIRST_BOOT" = true ] ; then
    touch ${DST_ROOTFS}/var/lib/resize_partition_flag
fi

echo "setting hostname"
echo ${SYNCLOUD_BOARD} > ${DST_ROOTFS}/etc/hostname
echo "127.0.0.1 ${SYNCLOUD_BOARD}" >> ${DST_ROOTFS}/etc/hosts
echo "::1 ${SYNCLOUD_BOARD}" >> ${DST_ROOTFS}/etc/hosts

sync

cleanup

ls -la ${DST_ROOTFS}

echo "fdisk info:"
fdisk -l ${SYNCLOUD_IMAGE}

echo "zipping"
xz -0 ${SYNCLOUD_IMAGE} -k

ls -la ${SYNCLOUD_IMAGE}.xz

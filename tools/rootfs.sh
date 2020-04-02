#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. ${DIR}/functions.sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -ne 5 ]]; then
    echo "Usage: $0 board arch image release distro"
    exit 1
fi

SYNCLOUD_BOARD=$1
ARCH=$2
SYNCLOUD_IMAGE=$3
RELEASE=$4
DISTRO=$5

SRC_FILES=files/${SYNCLOUD_BOARD}
SRC_ROOTFS=rootfs_${SYNCLOUD_BOARD}
DST_ROOTFS=dst_${SYNCLOUD_BOARD}/root
ROOTFS_FILE=rootfs-${DISTRO}-${ARCH}.tar.gz
echo "==== ${SYNCLOUD_BOARD}, ${ARCH} ===="

if [[ ! -f ${ROOTFS_FILE} ]]; then
    wget https://github.com/syncloud/rootfs/releases/download/${RELEASE}/${ROOTFS_FILE} --progress dot:giga
else
    echo "$ROOTFS_FILE is here"
fi

mkdir ${SRC_ROOTFS}
tar xzf ${ROOTFS_FILE} -C${SRC_ROOTFS}
cat ${SRC_ROOTFS}/etc/hosts
rm -rf ${ROOTFS_FILE}

LOOP=$(attach_image ${SYNCLOUD_IMAGE})
DEVICE_PART_1=/dev/mapper/${LOOP}p1
DEVICE_PART_2=/dev/mapper/${LOOP}p2
sync
fsck -fy ${DEVICE_PART_2}
UUID_FILE=${SYNCLOUD_BOARD}/root/uuid
if [[ -f "${UUID_FILE}" ]]; then
    UUID=$(<${UUID_FILE})
    change_uuid ${DEVICE_PART_2} ${UUID}
fi

mount ${DEVICE_PART_2} ${DST_ROOTFS}

ls -la ${SRC_ROOTFS}
ls -la ${SRC_ROOTFS}/etc
cat ${SRC_ROOTFS}/etc/hosts

ls -la ${DST_ROOTFS}
ls -la ${SYNCLOUD_BOARD}/root/
ls -la ${SYNCLOUD_BOARD}/root/etc

echo "copying rootfs"
cp -rp ${SRC_ROOTFS}/* ${DST_ROOTFS}/
cat ${DST_ROOTFS}/etc/hosts

rm -rf ${SRC_ROOTFS}
cp -rp ${SYNCLOUD_BOARD}/root/* ${DST_ROOTFS}/

echo "copying files"
cp -rp ${SRC_FILES}/* ${DST_ROOTFS}/

if [[ ${ARCH} == "amd64"  ]]; then

  cat ${DST_ROOTFS}/etc/fstab

  DEVICE_PART_1_UUID=$(blkid ${DEVICE_PART_1} -s UUID -o value)
  sed -i 's#/dev/sda1#UUID='${DEVICE_PART_1_UUID}'#g' ${DST_ROOTFS}/etc/fstab

  DEVICE_PART_2_UUID=$(blkid ${DEVICE_PART_2} -s UUID -o value)
  sed -i 's#/dev/sda2#UUID='${DEVICE_PART_2_UUID}'#g' ${DST_ROOTFS}/etc/fstab

  cat ${DST_ROOTFS}/etc/fstab

fi

echo "setting hostname"
echo syncloud > ${DST_ROOTFS}/etc/hostname

cat ${DST_ROOTFS}/etc/hosts
echo "127.0.0.1 syncloud" >> ${DST_ROOTFS}/etc/hosts
echo "::1 syncloud" >> ${DST_ROOTFS}/etc/hosts
grep localhost ${DST_ROOTFS}/etc/hosts

sync

cleanup ${DST_ROOTFS} ${SRC_ROOTFS} ${SYNCLOUD_IMAGE}

ls -la ${DST_ROOTFS}

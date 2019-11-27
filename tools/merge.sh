#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 board arch image"
    exit 1
fi

SYNCLOUD_BOARD=$1
ARCH=$2
SYNCLOUD_IMAGE=$3

ROOTFS_FILE=rootfs-${ARCH}.tar.gz
echo "==== ${SYNCLOUD_BOARD}, ${ARCH} ===="

if [[ ! -f ${ROOTFS_FILE} ]]; then
    wget https://github.com/syncloud/rootfs/releases/download/1/${ROOTFS_FILE} --progress dot:giga
else
    echo "$ROOTFS_FILE is here"
fi

BOOT_ZIP=${SYNCLOUD_BOARD}.tar.gz
if [[ ! -f ${BOOT_ZIP} ]]; then
  echo "missing ${BOOT_ZIP}"
  exit 1
fi

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

SRC_ROOTFS=rootfs_${SYNCLOUD_BOARD}
DST_ROOTFS=dst_${SYNCLOUD_BOARD}/root

SRC_FILES=files/${SYNCLOUD_BOARD}

function cleanup {
    echo "==== cleanup ===="

    ls -la /dev/mapper/*
    mount | grep ${DST_ROOTFS} || true
    mount | grep ${DST_ROOTFS} | awk '{print "umounting "$1; system("umount "$3)}' || true
    mount | grep ${DST_ROOTFS} || true
    rm -rf ${SRC_ROOTFS}
    losetup -a
    kpartx -v ${SYNCLOUD_IMAGE} || true
    echo "removing loop devices"
    kpartx -d ${SYNCLOUD_IMAGE} || true
    rm -rf ${SYNCLOUD_BOARD}
    dmsetup remove -f /dev/mapper/loop* || true

    echo "==== cleanup end ===="
}

cleanup

mkdir ${SRC_ROOTFS}
tar xzf ${ROOTFS_FILE} -C${SRC_ROOTFS}
cat ${SRC_ROOTFS}/etc/hosts
rm -rf ${ROOTFS_FILE}

echo "extracting boot"
rm -rf ${SYNCLOUD_BOARD}
tar xzf ${BOOT_ZIP}
ls -la
rm -rf ${BOOT_ZIP}

echo "copying boot"
cp ${SYNCLOUD_BOARD}/boot ${SYNCLOUD_IMAGE}

BOOT_BYTES=$(wc -c "${SYNCLOUD_IMAGE}" | cut -f 1 -d ' ')
BOOT_SECTORS=$(( ${BOOT_BYTES} / 512 ))
echo "boot sectors: ${BOOT_SECTORS}"

ROOTFS_SECTORS=$(( 3 * 1024 * 1024 "* 2 ))
dd if=/dev/zero count=${ROOTFS_SECTORS} >> ${SYNCLOUD_IMAGE}
ROOTFS_START_SECTOR=$(( ${BOOT_SECTORS} + 1  ))
ROOTFS_END_SECTOR=$(( ${ROOTFS_START_SECTOR} + ${ROOTFS_SECTORS} - 2 ))
fdisk -l ${SYNCLOUD_IMAGE}

echo "creating second partition (${ROOTFS_START_SECTOR} - ${ROOTFS_END_SECTOR}) sectors"
echo "
n
p
2
${ROOTFS_START_SECTOR}
${ROOTFS_END_SECTOR}
w
q
" | fdisk ${SYNCLOUD_IMAGE}

sync

ls -la /dev/mapper/*

kpartx -l ${SYNCLOUD_IMAGE}
kpartx -avs ${SYNCLOUD_IMAGE} | tee kpartx.out
sync
LOOP=loop$(cat kpartx.out | grep loop | head -1 | cut -d ' ' -f3 | cut -d p -f 2)

rm -rf dst_${SYNCLOUD_BOARD}
mkdir -p ${DST_ROOTFS}

ls -la /dev/mapper/*
sync

DEVICE_PART_1=/dev/mapper/${LOOP}p1
DEVICE_PART_2=/dev/mapper/${LOOP}p2

export MKE2FS_SYNC=2
set +e
mkfs.ext4 -D -E lazy_itable_init=0,lazy_journal_init=0 ${DEVICE_PART_2}
if [[ $? -ne 0 ]]; then
    cleanup
    exit 1
fi
set -e
sync

fsck -fy ${DEVICE_PART_2}

UUID_FILE=${SYNCLOUD_BOARD}/root/uuid

function change_uuid {

    local DEVICE=$1
    local UUID=$2
    FSTYPE=$(lsblk ${DEVICE} -o FSTYPE | tail -1)
    if [[ ${FSTYPE} == "ext"* ]]; then
        blkid ${DEVICE} -s UUID -o value
        tune2fs ${DEVICE} -U ${UUID}
        blkid ${DEVICE} -s UUID -o value
    else
        echo "not changing non ext fs uuid"
    fi

}

if [[ -f "${UUID_FILE}" ]]; then
    UUID=$(<${UUID_FILE})
    
    change_uuid ${DEVICE_PART_1} clear
    change_uuid ${DEVICE_PART_2} ${UUID}
   
fi

mount ${DEVICE_PART_2} ${DST_ROOTFS}

ls -la ${SRC_ROOTFS}
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

if [[ -f ${DST_ROOTFS}/etc/fstab.vbox ]]; then
  mv ${DST_ROOTFS}/etc/fstab.vbox ${DST_ROOTFS}/etc/fstab

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

cleanup

ls -la ${DST_ROOTFS}

echo "fdisk info:"
fdisk -l ${SYNCLOUD_IMAGE}

echo "zipping"
pxz -0 ${SYNCLOUD_IMAGE}

ls -la ${SYNCLOUD_IMAGE}.xz

ls -la
df -h

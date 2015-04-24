#!/bin/bash

START_TIME=$(date +"%s")

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 board_name"
    exit 1
fi

echo "Building board: ${SYNCLOUD_BOARD}"

SYNCLOUD_BOARD=$1

RESIZE_PARTITION_ON_FIRST_BOOT=true
CPU_FREQUENCY_CONTROL=false
CPU_FREQUENCY_GOVERNOR=
CPU_FREQUENCY_MAX=
CPU_FREQUENCY_MIN=

if [[ ${SYNCLOUD_BOARD} == "raspberrypi" || ${SYNCLOUD_BOARD} == "raspberrypi2" ]]; then
  BOOT_NAME=Cubian-nano+headless-x1-a20-cubietruck
elif [[ ${SYNCLOUD_BOARD} == "beagleboneblack" ]]; then
  BOOT_NAME=Cubian-nano+headless-x1-a20-cubietruck
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  BOOT_NAME=Cubian-nano+headless-x1-a20-cubietruck
elif [[ ${SYNCLOUD_BOARD} == "cubieboard2" ]]; then
  BOOT_NAME=Cubian-nano+headless-x1-a20-cubietruck
elif [[ ${SYNCLOUD_BOARD} == "cubietruck" ]]; then
  BOOT_NAME=Cubian-nano+headless-x1-a20-cubietruck
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "odroid-xu3" ]]; then
  BOOT_NAME=Cubian-nano+headless-x1-a20-cubietruck
fi

BOOT_URL=https://s3-us-west-2.amazonaws.com/syncloud
BOOT_ZIP=${BOOT_NAME}.tar.gz
SYNCLOUD_IMAGE=syncloud-${SYNCLOUD_BOARD}.img

echo "installing dependencies"
sudo apt-get -y install dosfstools kpartx p7zip

if [ ! -f ${BOOT_ZIP} ]; then
  echo "getting boot"
  wget ${BOOT_URL}/${BOOT_ZIP}
else
  echo "$BOOT_ZIP is here"
fi
echo "extracting boot"
rm -rf ${BOOT_NAME}
tar xzf ${BOOT_ZIP}

echo "copying boot"
cp ${BOOT_NAME}/boot ${SYNCLOUD_IMAGE}
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
LOOP=$(kpartx -l ${SYNCLOUD_IMAGE} | head -1 | cut -d ' ' -f1 | cut -c1-5)
rm -rf dst
mkdir -p dst/root

mkfs.ext4 /dev/mapper/${LOOP}p2
mount /dev/mapper/${LOOP}p2 dst/root

echo "extracting rootfs"
cp -r rootfs/* dst/root/
cp -r ${BOOT_NAME}/root/* dst/root/

echo "applying cpu frequency fix"
if [ "$CPU_FREQUENCY_CONTROL" = true ] ; then
    touch dst/root/var/lib/cpu_frequency_control
    echo -n ${CPU_FREQUENCY_GOVERNOR} > dst/root/var/lib/cpu_frequency_governor
    echo -n ${CPU_FREQUENCY_MAX} > dst/root/var/lib/cpu_frequency_max
    echo -n ${CPU_FREQUENCY_MIN} > dst/root/var/lib/cpu_frequency_min
fi

echo "setting resize on boot flag"
if [ "$RESIZE_PARTITION_ON_FIRST_BOOT" = true ] ; then
    touch dst/root/var/lib/resize_partition_flag
fi

echo "setting hostname"
echo ${SYNCLOUD_BOARD} > dst/root/etc/hostname

echo "setting hosts"
echo "::1 localhost ip6-localhost ip6-loopback" > dst/root/ets/hosts
echo "fe00::0 ip6-localnet" >> dst/root/etc/hosts
echo "ff00::0 ip6-mcastprefix" >> dst/root/etc/hosts
echo "ff02::1 ip6-allnodes" >> dst/root/etc/hosts
echo "ff02::2 ip6-allrouters" >> dst/root/etc/hosts
echo "127.0.0.1 localhost" >> dst/root/etc/hosts

echo "unmounting image"
umount /dev/mapper/${LOOP}p2
kpartx -d ${SYNCLOUD_IMAGE}

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))
echo "image: ${SYNCLOUD_IMAGE}"
echo "Build time: $(($BUILD_TIME / 60)) min"


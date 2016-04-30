#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$1" == "" ]; then
    echo "Usage: $0 board"
    exit 1
fi

apt-get install -y kpartx

SYNCLOUD_BOARD=$1

CPU_FREQUENCY_CONTROL=false
CPU_FREQUENCY_GOVERNOR=
CPU_FREQUENCY_MAX=
CPU_FREQUENCY_MIN=

if [[ ${SYNCLOUD_BOARD} == "raspberrypi2" ]]; then
#  DIR_VERSION=2015-11-24; FILE_VERSION=2015-11-21
#  DIR_VERSION=2016-02-09; FILE_VERSION=2016-02-09
#  DIR_VERSION=2016-02-26; FILE_VERSION=2016-02-26
  DIR_VERSION=2016-03-18; FILE_VERSION=2016-03-18
  IMAGE_FILE=/tmp/${FILE_VERSION}-raspbian-jessie-lite.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-${DIR_VERSION}/${FILE_VERSION}-raspbian-jessie-lite.zip -O $IMAGE_FILE_ZIP"
  UNZIP="unzip -o"
elif [[ ${SYNCLOUD_BOARD} == "raspberrypi3" ]]; then
#  DIR_VERSION=2016-02-09; FILE_VERSION=2016-02-09
#  DIR_VERSION=2016-02-29; FILE_VERSION=2016-02-26
  DIR_VERSION=2016-03-18; FILE_VERSION=2016-03-18
  IMAGE_FILE=/tmp/${FILE_VERSION}-raspbian-jessie-lite.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-${DIR_VERSION}/${FILE_VERSION}-raspbian-jessie-lite.zip -O $IMAGE_FILE_ZIP"
  UNZIP="unzip -o"
elif [[ ${SYNCLOUD_BOARD} == "beagleboneblack" ]]; then
  IMAGE_FILE=/tmp/${SYNCLOUD_BOARD}.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga http://builds.beagleboard.org/images/master/08132bf0d0cb284d1148c5d329fe3c8e1aaee44d/bone-debian-8.2-tester-2gb-armhf-2015-11-12-2gb.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  IMAGE_FILE="/tmp/Cubian-nano+headless-x1-a10.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.7z
  DOWNLOAD_IMAGE="wget --progress=dot:giga https://s3-us-west-2.amazonaws.com/syncloud-distributives/Cubian-nano%2Bheadless-x1-a10.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "cubieboard2" ]]; then
  IMAGE_FILE="/tmp/Cubian-nano+headless-x1-a20.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.7z
  DOWNLOAD_IMAGE="wget --progress=dot:giga https://s3-us-west-2.amazonaws.com/syncloud-distributives/Cubian-nano%2Bheadless-x1-a20.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "cubietruck" ]]; then
  IMAGE_FILE="/tmp/Cubian-nano+headless-x1-a20-cubietruck.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.7z
  DOWNLOAD_IMAGE="wget --progress=dot:giga https://s3-us-west-2.amazonaws.com/syncloud-distributives/Cubian-nano%2Bheadless-x1-a20-cubietruck.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "odroid-xu3and4" ]]; then
  IMAGE_FILE="/tmp/ubuntu-14.04lts-server-odroid-xu3-20150725.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga http://odroid.in/ubuntu_14.04lts/ubuntu-14.04lts-server-odroid-xu3-20150725.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "odroid-c2" ]]; then
  IMAGE_FILE="/tmp/ubuntu64-16.04lts-mate-odroid-c2-20160226.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga http://east.us.odroid.in/ubuntu_16.04lts/${IMAGE_FILE_ZIP} -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "bananapim2" ]]; then
  IMAGE_FILE="/tmp/M2-raspberry-kernel3.3-LCD.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga http://3rdparty.syncloud.org/BPI-M2_Raspbian_V4.0_lcd.zip -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
else
    echo "board is not supported: ${SYNCLOUD_BOARD}"
    exit 1
fi

PARTED_SECTOR_UNIT=s
DD_SECTOR_UNIT=b
OUTPUT=${SYNCLOUD_BOARD}

function cleanup {
    echo "cleanup"
    umount extract_rootfs
    umount boot
    kpartx -d ${IMAGE_FILE}
}

apt-get install unzip

cleanup

if [ ! -z "$TEAMCITY_VERSION" ]; then
  echo "running under TeamCity, cleaning base image cache"
  rm -rf ${IMAGE_FILE}
fi

if [ ! -f ${IMAGE_FILE} ]; then
  echo "Base image $IMAGE_FILE is not found, getting new one ..."
  ${DOWNLOAD_IMAGE}
  pushd .
  cd /tmp
  ls -la
  ${UNZIP} ${IMAGE_FILE_ZIP}
  popd
fi

parted -sm ${IMAGE_FILE} print | tail -n +3

PARTITIONS=$(parted -sm ${IMAGE_FILE} print | tail -n +3 | wc -l)
if [ ${PARTITIONS} == 1 ]; then
    echo "single partition is not supported yet"
    exit 1
fi

BOOT_PARTITION_END_SECTOR=$(parted -sm ${IMAGE_FILE} unit ${PARTED_SECTOR_UNIT} print | grep "^1" | cut -d ':' -f3 | cut -d 's' -f1)
rm -rf ${OUTPUT}
mkdir ${OUTPUT}

echo "applying cpu frequency fix"
if [ "$CPU_FREQUENCY_CONTROL" = true ] ; then
    mkdir -p ${OUTPUT}/root/var/lib
    touch ${OUTPUT}/root/var/lib/cpu_frequency_control
    echo -n ${CPU_FREQUENCY_GOVERNOR} > ${OUTPUT}/root/var/lib/cpu_frequency_governor
    echo -n ${CPU_FREQUENCY_MAX} > ${OUTPUT}/root/var/lib/cpu_frequency_max
    echo -n ${CPU_FREQUENCY_MIN} > ${OUTPUT}/root/var/lib/cpu_frequency_min
fi

echo "fixing boot"

LOOP=$(kpartx -l ${IMAGE_FILE} | head -1 | cut -d ' ' -f1 | cut -c1-5)

echo "LOOP: ${LOOP}"

rm -rf boot
mkdir -p boot
kpartx -avs ${IMAGE_FILE}
mount /dev/mapper/${LOOP}p1 boot

mount | grep boot

ls -la boot/

boot_ini=boot/boot.ini
if [ -f ${boot_ini} ]; then
    cat ${boot_ini}
    sed -i 's#root=.* #root=/dev/mmcblk0p2 #g' ${boot_ini}
    cat ${boot_ini}
fi

rm -rf ${OUTPUT}-boot.tar.gz
tar czf ${OUTPUT}-boot.tar.gz boot

umount /dev/mapper/${LOOP}p1
kpartx -d ${IMAGE_FILE}
rm -rf boot

echo "extracting boot partition with boot loader"
dd if=${IMAGE_FILE} of=${OUTPUT}/boot bs=1${DD_SECTOR_UNIT} count=$(( ${BOOT_PARTITION_END_SECTOR} ))

echo "extracting kernel modules and firmware from rootfs"

rm -rf extract_rootfs
mkdir -p extract_rootfs
kpartx -avs ${IMAGE_FILE}
LOOP=$(kpartx -l ${IMAGE_FILE} | head -1 | cut -d ' ' -f1 | cut -c1-5)
mount /dev/mapper/${LOOP}p2 extract_rootfs

mount | grep extract_rootfs

losetup -l

echo "source rootfs"
ls -la extract_rootfs/
ls -la extract_rootfs/lib/modules

echo "target rootfs"
ls -la ${OUTPUT}

mkdir -p ${OUTPUT}/root/lib
cp -rp extract_rootfs/lib/firmware ${OUTPUT}/root/lib/firmware
cp -rp extract_rootfs/lib/modules ${OUTPUT}/root/lib/modules
sync

cleanup

rm -rf ${OUTPUT}.tar.gz
tar czf ${OUTPUT}.tar.gz ${OUTPUT}

echo "result: $OUTPUT.tar.gz"


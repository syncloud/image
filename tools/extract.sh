#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$3" == "" ]; then
    echo "Usage: $0 board installer base_image"
    exit 1
fi

SYNCLOUD_BOARD=$1
INSTALLER=$2
IMAGE_FILE_NORMALIZED=$3
BUILD_DIR=${DIR}/build_${SYNCLOUD_BOARD}
rm -rf ${BUILD_DIR}
mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

CPU_FREQUENCY_CONTROL=false
CPU_FREQUENCY_GOVERNOR=
CPU_FREQUENCY_MAX=
CPU_FREQUENCY_MIN=

SYNCLOUD_DISTR_URL="http://artifact.syncloud.org/image/base"

if [[ ${SYNCLOUD_BOARD} == "raspberrypi2" ]]; then
  FILE_VERSION=2016-03-18
  IMAGE_FILE=${FILE_VERSION}-raspbian-jessie-lite.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${FILE_VERSION}-raspbian-jessie-lite.zip -O $IMAGE_FILE_ZIP"
  UNZIP="unzip -o"
elif [[ ${SYNCLOUD_BOARD} == "raspberrypi3" ]]; then
  FILE_VERSION=2016-03-18
  IMAGE_FILE=${FILE_VERSION}-raspbian-jessie-lite.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${FILE_VERSION}-raspbian-jessie-lite.zip -O $IMAGE_FILE_ZIP"
  UNZIP="unzip -o"
elif [[ ${SYNCLOUD_BOARD} == "tinker" ]]; then
  FILE_VERSION=20171115
  IMAGE_FILE=${FILE_VERSION}-tinker-board-linaro-stretch-alip-v2.0.4.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${FILE_VERSION}-tinker-board-linaro-stretch-alip-v2.0.4.zip -O $IMAGE_FILE_ZIP"
  UNZIP="unzip -o"
elif [[ ${SYNCLOUD_BOARD} == "beagleboneblack" ]]; then
  IMAGE_FILE=${SYNCLOUD_BOARD}.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/bone-debian-8.7-lxqt-4gb-armhf-2017-03-19-4gb.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  IMAGE_FILE="Cubian-nano+headless-x1-a10.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.7z
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/Cubian-nano%2Bheadless-x1-a10.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "cubieboard2" ]]; then
  IMAGE_FILE="Cubian-nano+headless-x1-a20.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.7z
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/Cubian-nano%2Bheadless-x1-a20.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "cubietruck" ]]; then
  IMAGE_FILE="Armbian_5.31_Cubietruck_Debian_jessie_next_4.11.5.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.7z
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/$IMAGE_FILE_ZIP -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
elif [[ ${SYNCLOUD_BOARD} == "odroid-xu3and4" ]]; then
  IMAGE_FILE_NAME="ubuntu-16.04.3-4.9-mate-odroid-xu4-20170824.img"
  IMAGE_FILE=${IMAGE_FILE_NAME}
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_NAME}.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "odroid-c2" ]]; then
  IMAGE_FILE="ubuntu64-16.04lts-mate-odroid-c2-20160226.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/ubuntu64-16.04lts-mate-odroid-c2-20160226.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "bananapim2" ]]; then
  IMAGE_FILE="M2-raspberry-kernel3.3-LCD.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/BPI-M2_Raspbian_V4.0_lcd.zip -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
elif [[ ${SYNCLOUD_BOARD} == "bananapim1" ]]; then
  IMAGE_FILE="BPI-M1_Debian_V2_beta.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/BPI-M1_Debian_V2_beta.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "bananapim3" ]]; then
  IMAGE_FILE_NAME="2016-05-15-debian-8-jessie-lite-bpi-m3-sd-emmc.img"
  IMAGE_FILE=${IMAGE_FILE_NAME}
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_NAME}.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
elif [[ ${SYNCLOUD_BOARD} == "vbox" ]]; then
  IMAGE_FILE_NAME="debian-vbox-8gb.img"
  IMAGE_FILE=${IMAGE_FILE_NAME}
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/$IMAGE_FILE_NAME.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
else
    echo "board is not supported: ${SYNCLOUD_BOARD}"
    exit 1
fi

PARTED_SECTOR_UNIT=s
DD_SECTOR_UNIT=b
OUTPUT=${DIR}/../${SYNCLOUD_BOARD}
ROOTFS=${DIR}/extract_${SYNCLOUD_BOARD}
BOOT=${DIR}/boot_${SYNCLOUD_BOARD}

function cleanup {
    echo "cleanup"
    umount ${ROOTFS} || true
    umount ${BOOT} || true
    kpartx -d ${IMAGE_FILE_NORMALIZED} || true
    losetup -l | tee losetup.out
    LOOP=$(cat losetup.out | grep ${IMAGE_FILE_NORMALIZED} | cut -d ' ' -f1 | cut -d '/' -f3) || true
    if [[ ${LOOP} != "" ]]; then
         dmsetup remove -f /dev/mapper/${LOOP}p1 | true
         dmsetup remove -f /dev/mapper/${LOOP}p2 | true
         losetup -d /dev/${LOOP} | true
         losetup
    fi
    rm -rf *.img
    rm -rf ${ROOTFS}
}

function extract_root {
    echo "extracting kernel modules and firmware from rootfs"
    local from=$1
    local to=$2
    echo "source rootfs"
    ls -la ${from}/
    ls -la ${from}/lib/modules
    ls -la ${from}/boot

    echo "target rootfs"
    ls -la ${to}

    mkdir -p ${to}/lib
    cp -rp ${from}/lib/firmware ${to}/lib/firmware
    cp -rp ${from}/lib/modules ${to}/lib/modules
    if [ -d ${from}/lib/mali-egl ]; then
        ls -la ${from}/lib/mali-egl
        cp -rp ${from}/lib/mali-egl ${to}/lib/mali-egl
    fi
    
    cp -rp ${from}/boot ${to}/boot
    sync

}

cleanup

if [ ! -z "$CI" ]; then
  echo "running under CI, cleaning base image cache"
  rm -rf ${IMAGE_FILE_ZIP}
fi

if [ ! -f ${IMAGE_FILE_ZIP} ]; then
  echo "Base image $IMAGE_FILE_ZIP is not found, getting new one ..."
  ${DOWNLOAD_IMAGE}
  ls -la
  ${UNZIP} ${IMAGE_FILE_ZIP}
  mv ${IMAGE_FILE} ${IMAGE_FILE_NORMALIZED}
  IMAGE_FILE=${IMAGE_FILE_NORMALIZED}
  rm -rf ${IMAGE_FILE_ZIP}
  ls -la
fi

if [ ! -f ${IMAGE_FILE} ]; then
  echo "${IMAGE_FILE} not found"
  exit 1
fi

echo "fdisk info:"
fdisk -l ${IMAGE_FILE}

echo "parted info:"
parted -sm ${IMAGE_FILE} print | tail -n +3

TOTAL_BYTES=$(stat -c %s ${IMAGE_FILE})
TOTAL_SECTORS=$(($TOTAL_BYTES/512))
LAST_SECTOR=$(fdisk -o End -l ${IMAGE_FILE}| tail -1)
SECTORS_MISSING=$(($LAST_SECTOR-$TOTAL_SECTORS+1))
if [ "${SECTORS_MISSING}" -gt "0" ]; then
    echo "appending missing bytes"
    dd if=/dev/zero bs=512 count=${SECTORS_MISSING} >> ${IMAGE_FILE}
fi
PARTITIONS=$(parted -sm ${IMAGE_FILE} print | tail -n +3 | wc -l)
parted -sm ${IMAGE_FILE} unit ${PARTED_SECTOR_UNIT} print | tee parted.out
BOOT_PARTITION_END_SECTOR=$( cat parted.out | grep "^1" | cut -d ':' -f3 | cut -d 's' -f1)

rm -rf ${OUTPUT}
mkdir ${OUTPUT}
mkdir ${OUTPUT}/root

echo "applying cpu frequency fix"
if [ "$CPU_FREQUENCY_CONTROL" = true ] ; then
    mkdir -p ${OUTPUT}/root/var/lib
    touch ${OUTPUT}/root/var/lib/cpu_frequency_control
    echo -n ${CPU_FREQUENCY_GOVERNOR} > ${OUTPUT}/root/var/lib/cpu_frequency_governor
    echo -n ${CPU_FREQUENCY_MAX} > ${OUTPUT}/root/var/lib/cpu_frequency_max
    echo -n ${CPU_FREQUENCY_MIN} > ${OUTPUT}/root/var/lib/cpu_frequency_min
fi

echo "fixing boot"

rm -rf ${BOOT}
mkdir -p ${BOOT}
kpartx -avs ${IMAGE_FILE} | tee kpartx.out
sync
LOOP=loop$(cat kpartx.out | grep loop | head -1 | cut -d ' ' -f3 | cut -d p -f 2)
echo "LOOP: ${LOOP}"

FS_TYPE=$(blkid -s TYPE -o value /dev/mapper/${LOOP}p1)
if [[ "${FS_TYPE}" == *"swap"*  ]]; then
    echo "not inspecting boot partition as it is: ${FS_TYPE}"
else
    echo "inspecting boot partition"

    mount /dev/mapper/${LOOP}p1 ${BOOT}

    mount | grep ${BOOT}

    ls -la ${BOOT}/
    
    if [ ${PARTITIONS} == 1 ]; then
    
        if [ ! -d ${BOOT}/boot ]; then
            echo "single partition images without boot dir are not supported yet"
            exit 1
        fi
        
        ls -la ${BOOT}/boot
        if [ -f ${BOOT}/boot/armbianEnv.txt ]; then
            cat ${BOOT}/boot/armbianEnv.txt
            sed -i 's#rootdev=.*#rootdev=/dev/mmcblk0p2#g' ${BOOT}/boot/armbianEnv.txt
            cat ${BOOT}/boot/armbianEnv.txt
        fi

        #if [ -f ${BOOT}/boot/boot.cmd ]; then
        #    cat ${BOOT}/boot/boot.cmd
        #    sed -i 's#setenv rootdev .*#setenv rootdev "/dev/mmcblk0p2"#g' ${BOOT}/boot/boot.cmd
        #    cat ${BOOT}/boot/boot.cmd
        #    mkimage -C none -A arm -T script -d ${BOOT}/boot/boot.cmd ${BOOT}/boot/boot.scr
        #    cat ${BOOT}/boot/boot.scr
        #fi

        extract_root ${BOOT} ${OUTPUT}/root

        cd ${BOOT}
        ls -la
        ls | grep -v boot | xargs rm -rf
        ls -la
        cd ${BUILD_DIR}
        
        sync
        umount /dev/mapper/${LOOP}p1
        fsck -fy /dev/mapper/${LOOP}p1 || true
        BOOT_SIZE_MB=200
        resize2fs /dev/mapper/${LOOP}p1 ${BOOT_SIZE_MB}M
        pwd
        ls -la
        BOOT_PARTITION_START_SECTOR=$(parted -sm ${IMAGE_FILE} unit ${PARTED_SECTOR_UNIT} print | grep "^1" | cut -d ':' -f2 | cut -d 's' -f1)
        BOOT_SIZE_SECTORS=$((${BOOT_SIZE_MB}*1024*2))
        BOOT_PARTITION_END_SECTOR=$(($BOOT_PARTITION_START_SECTOR+$BOOT_SIZE_SECTORS))
        kpartx -d ${IMAGE_FILE} || true # not sure why this is not working sometimes

echo "
p
d
w
" | fdisk ${IMAGE_FILE}


echo "
n
p
1
${BOOT_PARTITION_START_SECTOR}
${BOOT_PARTITION_END_SECTOR}
w
q
" | fdisk ${IMAGE_FILE}

        fdisk -lu ${IMAGE_FILE}
        parted -sm ${IMAGE_FILE}
    else

        boot_ini=${BOOT}/boot.ini
        if [ -f ${boot_ini} ]; then
            cat ${boot_ini}
            sed -i 's#root=.* #root=/dev/mmcblk0p2 #g' ${boot_ini}
            cat ${boot_ini}
        fi

        cmdline_txt=${BOOT}/cmdline.txt
        if [ -f ${cmdline_txt} ]; then
            cat ${cmdline_txt}
            sed -i 's#init=.* #init=/sbin/init #g' ${cmdline_txt}
            sed -i 's#root=.* #root=/dev/mmcblk0p2 #g' ${cmdline_txt}
            cat ${cmdline_txt}
        fi
        
        umount /dev/mapper/${LOOP}p1
        parted -sm ${IMAGE_FILE} unit ${PARTED_SECTOR_UNIT} print | tee parted.out
        BOOT_PARTITION_END_SECTOR=$( cat parted.out | grep "^1" | cut -d ':' -f3 | cut -d 's' -f1)
        kpartx -d ${IMAGE_FILE} || true # not sure why this is not working sometimes

    fi

#    rm -rf ${OUTPUT}-boot.tar.gz
#    tar czf ${OUTPUT}-boot.tar.gz $BOOT

    rm -rf ${BOOT}

fi

if [ ${PARTITIONS} == 2 ]; then

    kpartx -avs ${IMAGE_FILE}
    rm -rf ${ROOTFS}
    mkdir -p ${ROOTFS}
    ROOTFS_LOOP=${LOOP}p2
    sync
    blkid /dev/mapper/${ROOTFS_LOOP} -s UUID -o value > uuid
    fsck -fy /dev/mapper/${ROOTFS_LOOP} || true
    mount /dev/mapper/${ROOTFS_LOOP} ${ROOTFS}
    mount | grep ${ROOTFS}

    losetup -l
    extract_root ${ROOTFS} ${OUTPUT}/root
    cp uuid ${OUTPUT}/root/uuid

    echo "
d
2
w
" | fdisk ${IMAGE_FILE}

fi

echo "extracting boot partition with boot loader"

parted -sm ${IMAGE_FILE} unit ${PARTED_SECTOR_UNIT} print
fdisk -lu ${IMAGE_FILE}

dd if=${IMAGE_FILE} of=${OUTPUT}/boot bs=1${DD_SECTOR_UNIT} count=$(( ${BOOT_PARTITION_END_SECTOR} + 1 ))

fdisk -lu ${OUTPUT}/boot
parted -sm ${OUTPUT}/boot print

cleanup
rm -rf ${IMAGE_FILE}
rm -rf ${OUTPUT}.tar.gz
tar -c --use-compress-program=pigz -f ${OUTPUT}.tar.gz -C ${DIR}/.. ${SYNCLOUD_BOARD}
rm -rf ${OUTPUT}
echo "result: $OUTPUT.tar.gz"

ls -la
df -h

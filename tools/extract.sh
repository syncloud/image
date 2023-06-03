#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 board base_image"
    exit 1
fi

SYNCLOUD_BOARD=$1
IMAGE_FILE_NORMALIZED=$2
BUILD_DIR=${DIR}/build_${SYNCLOUD_BOARD}
rm -rf ${BUILD_DIR}
mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

CPU_FREQUENCY_CONTROL=false
CPU_FREQUENCY_GOVERNOR=
CPU_FREQUENCY_MAX=
CPU_FREQUENCY_MIN=

SYNCLOUD_DISTR_URL="https://github.com/syncloud/base-image/releases/download/1"
UNZIP=unxz

apt update
apt install -y gdisk wget xz-utils kpartx unzip p7zip-full

if [[ ${SYNCLOUD_BOARD} == "raspberrypi2" ]]; then
  IMAGE_FILE=2016-03-18-raspbian-jessie-lite.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "tinker" ]]; then
  IMAGE_FILE="Armbian_20.02.7_Tinkerboard_bionic_legacy_4.4.213_desktop.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "beagleboneblack" ]]; then
  IMAGE_FILE=bone-debian-10.3-console-armhf-2020-04-06-1gb.img
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  IMAGE_FILE="Cubian-nano-headless-x1-a10.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "cubieboard2" ]]; then
  IMAGE_FILE="Cubian-nano-headless-x1-a20.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
  CPU_FREQUENCY_CONTROL=true
  CPU_FREQUENCY_GOVERNOR=performance
  CPU_FREQUENCY_MAX=1056000
  CPU_FREQUENCY_MIN=648000
elif [[ ${SYNCLOUD_BOARD} == "cubietruck" ]]; then
  IMAGE_FILE="Armbian_5.31_Cubietruck_Debian_jessie_next_4.11.5.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.7z
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/$IMAGE_FILE_ZIP -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
elif [[ ${SYNCLOUD_BOARD} == "helios4" ]]; then
  IMAGE_FILE="Armbian_5.68_Helios4_Debian_stretch_next_4.14.88.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "helios64" ]]; then
  IMAGE_FILE="Armbian_20.08.8_Helios64_buster_current_5.8.13.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "odroid-xu3and4" ]]; then
  IMAGE_FILE="ubuntu-22.04-5.4-minimal-odroid-xu4-20220721.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "odroid-c2" ]]; then
  IMAGE_FILE="ubuntu-18.04.3-3.16-minimal-odroid-c2-20190814.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "odroid-u3" ]]; then
  IMAGE_FILE="ubuntu-14.04.2lts-lubuntu-odroid-u-20150224.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "odroid-hc4" ]]; then
  IMAGE_FILE="debian-buster-server-odroidc4-20210301-5.11.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "bananapim2" ]]; then
  IMAGE_FILE="M2-raspberry-kernel3.3-LCD.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.zip
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/BPI-M2_Raspbian_V4.0_lcd.zip -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
elif [[ ${SYNCLOUD_BOARD} == "bananapim1" ]]; then
  IMAGE_FILE="BPI-M1_Debian_V2_beta.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "bananapim3" ]]; then
  IMAGE_FILE="2016-05-15-debian-8-jessie-lite-bpi-m3-sd-emmc.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "rock64" ]]; then
  IMAGE_FILE="Armbian_5.69_Rock64_Debian_stretch_default_4.4.167_desktop.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "odroid-n2" ]]; then
  IMAGE_FILE="ubuntu-18.04.2-4.9-minimal-odroid-n2-20190329.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "amd64" ]]; then
  IMAGE_FILE="debian-buster-amd64-8gb.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "amd64-uefi" ]]; then
  IMAGE_FILE="ubuntu-20.10-uefi-amd64-8gb.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "lime2" ]]; then
  IMAGE_FILE="Armbian_5.89.1_Olinuxino-a20_Debian_stretch_next_5.1.12.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "raspberrypi" ]]; then
  IMAGE_FILE="2021-12-02-raspios-buster-armhf-lite.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "raspberrypi-64" ]]; then
  IMAGE_FILE="2022-09-06-raspios-bullseye-arm64-lite.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
elif [[ ${SYNCLOUD_BOARD} == "jetson-nano" ]]; then
  IMAGE_FILE="Armbian_22.11.1_Jetson-nano_bullseye_current_5.19.17.img"
  IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
  DOWNLOAD_IMAGE="wget --progress=dot:giga ${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"
else
    echo "board is not supported: ${SYNCLOUD_BOARD}"
    exit 1
fi


DD_SECTOR_UNIT=b
OUTPUT=${DIR}/../${SYNCLOUD_BOARD}
ROOTFS=${DIR}/extract_${SYNCLOUD_BOARD}
BOOT=${DIR}/boot_${SYNCLOUD_BOARD}

function cleanup {
    echo "cleanup start"
    umount ${ROOTFS} || true
    umount ${BOOT} || true
    kpartx -d ${IMAGE_FILE_NORMALIZED} || true
    losetup -l | tee losetup.out
    LOOP=$(cat losetup.out | grep ${IMAGE_FILE_NORMALIZED} | cut -d ' ' -f1 | cut -d '/' -f3) || true
    if [[ ${LOOP} != "" ]]; then
         dmsetup remove -f /dev/mapper/${LOOP}p1 || true
         dmsetup remove -f /dev/mapper/${LOOP}p2 || true
         losetup -d /dev/${LOOP} || true
         losetup
    fi
    rm -rf *.img
    rm -rf ${ROOTFS}
    echo "cleanup end"
}

function extract_root {
    echo "extracting kernel modules and firmware from rootfs"
    local from=$1
    local to=$2
    echo "source rootfs"
    ls -la ${from}/
    ls -la ${from}/lib/modules
    ls -la ${from}/boot

    if [[ -f ${from}/boot/config.txt ]]; then
        echo "kernel config"
        grep SQUASH ${from}/boot/config.txt
    fi

    echo "target rootfs"
    ls -la ${to}

    mkdir -p ${to}/lib
    if [[ -d ${from}/lib/firmware ]]; then
      cp -rp ${from}/lib/firmware ${to}/lib/firmware
    fi
    cp -rp ${from}/lib/modules ${to}/lib/modules

    mkdir -p ${to}/etc
    if [[ -d ${from}/etc/modprobe.d ]]; then
        cp -rp ${from}/etc/modprobe.d ${to}/etc/modprobe.d
    fi

    if [[ -d ${from}/etc/modules-load.d ]]; then
        cp -rp ${from}/etc/modules-load.d ${to}/etc/modules-load.d
    fi

    if [[ -f ${from}/etc/modules ]]; then
        cp -p ${from}/etc/modules ${to}/etc/modules
    fi

    if [[ -d ${from}/lib/mali-egl ]]; then
        ls -la ${from}/lib/mali-egl
        cp -rp ${from}/lib/mali-egl ${to}/lib/mali-egl
    fi

    if [[ -d ${from}/etc/alternatives ]]; then
        find ${from} -name "cyfmac43455-sdio.bin"
        ls -la ${from}/etc/alternatives
        cp -rp ${from}/etc/alternatives ${to}/etc
    fi

#    do not include the whole /var/lib as it breaks dpkg database
#    if [[ -d ${from}/var/lib ]]; then
#        mkdir -p ${to}/var
#        cp -rp ${from}/var/lib ${to}/var
#    fi

    if [[ -d ${from}/opt ]]; then
        mkdir -p ${to}/original
        cp -rp ${from}/opt ${to}/original
        # beagle bone emmc migration dependency needed by:
        # /opt/scripts/tools/eMMC/init-eMMC-flasher-v3.sh
        if [[ -d ${from}/opt/backup ]]; then
            mkdir -p ${to}/opt
            cp -rp ${from}/opt/backup ${to}/opt
        fi
    fi

    cp -rp ${from}/boot ${to}/boot

    if [[ -f ${to}/boot/grub/grub.cfg ]]; then
        grep "linux.*/boot/vmlinuz" ${to}/boot/grub/grub.cfg
        sed -i 's#linux.*/boot/vmlinuz.*#& net.ifnames=0#g' ${to}/boot/grub/grub.cfg
        grep "linux.*/boot/vmlinuz" ${to}/boot/grub/grub.cfg
    fi

    sync

}

cleanup

if [[ -f ${HOME}/${IMAGE_FILE_NORMALIZED} ]]; then
  echo "copying image ..."
  cp ${HOME}/${IMAGE_FILE_NORMALIZED} ${IMAGE_FILE_NORMALIZED}
else
  echo "Base image ${HOME}/${IMAGE_FILE_NORMALIZED} is not found, getting new one ..."
  ${DOWNLOAD_IMAGE}
  ls -la
  ${UNZIP} ${IMAGE_FILE_ZIP}
  mv ${IMAGE_FILE} ${IMAGE_FILE_NORMALIZED}
  rm -rf ${IMAGE_FILE_ZIP}
  ls -la
fi
IMAGE_FILE=${IMAGE_FILE_NORMALIZED}

if [[ ! -f ${IMAGE_FILE} ]]; then
  echo "${IMAGE_FILE} not found"
  exit 1
fi

echo "fdisk info:"
fdisk -l ${IMAGE_FILE}

TOTAL_BYTES=$(stat -c %s ${IMAGE_FILE})
TOTAL_SECTORS=$(($TOTAL_BYTES/512))
LAST_SECTOR=$(fdisk -l ${IMAGE_FILE} | grep -v -e '^$' | tail -1 | awk '{ print $3 }')
SECTORS_MISSING=$(($LAST_SECTOR-$TOTAL_SECTORS+1))
if [[ "${SECTORS_MISSING}" -gt "0" ]]; then
    echo "appending missing bytes"
    dd if=/dev/zero bs=512 count=${SECTORS_MISSING} >> ${IMAGE_FILE}
fi
PARTITIONS=$(fdisk -l ${IMAGE_FILE} | grep ${IMAGE_FILE} | tail -n +2 | wc -l)
FDISK_OUTPUT=$(fdisk -l ${IMAGE_FILE} | grep ${IMAGE_FILE} | tail -n +2 | head -1)
FDISK_FIELD2=$(echo "${FDISK_OUTPUT}" | awk '{print $2}')
FDISK_FIELD3=$(echo "${FDISK_OUTPUT}" | awk '{print $3}')
FDISK_FIELD4=$(echo "${FDISK_OUTPUT}" | awk '{print $4}')
if [[ ${FDISK_FIELD2} == "*" ]]; then
    BOOT_PARTITION_START_SECTOR=${FDISK_FIELD3}
    BOOT_PARTITION_END_SECTOR=${FDISK_FIELD4}
else
    BOOT_PARTITION_START_SECTOR=${FDISK_FIELD2}
    BOOT_PARTITION_END_SECTOR=${FDISK_FIELD3}
fi

rm -rf ${OUTPUT}
mkdir ${OUTPUT}
mkdir ${OUTPUT}/root

echo "applying cpu frequency fix"
if [[ "$CPU_FREQUENCY_CONTROL" = true ]] ; then
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
    echo "inspecting first partition"

    mount /dev/mapper/${LOOP}p1 ${BOOT}

    mount | grep ${BOOT}

    ls -la ${BOOT}/
    
    if [[ ${PARTITIONS} == 1 ]]; then
        echo "single partition disk"
        touch ${OUTPUT}/root/single_partition

        if [[ ! -d ${BOOT}/boot ]]; then
            echo "single partition images without boot dir are not supported yet"
            exit 1
        fi
        
        if [[ -f ${BOOT}/bbb-uEnv.txt ]]; then
            cp ${BOOT}/bbb-uEnv.txt ${BOOT}/uEnv.txt
            sed -i 's#root=/dev/mmcblk0p1#root=/dev/mmcblk0p2#g' ${BOOT}/uEnv.txt
        fi
        
        ls -la ${BOOT}/boot
        if [[ -f ${BOOT}/boot/armbianEnv.txt ]]; then
            cat ${BOOT}/boot/armbianEnv.txt
            #sed -i 's#rootdev=.*#rootdev=/dev/mmcblk0p2#g' ${BOOT}/boot/armbianEnv.txt
            #cat ${BOOT}/boot/armbianEnv.txt
        fi
        
        echo "kernel config"
        ls -la ${BOOT}/boot/config-* || true

        #if [ -f ${BOOT}/boot/boot.cmd ]; then
        #    cat ${BOOT}/boot/boot.cmd
        #    sed -i 's#setenv rootdev .*#setenv rootdev "/dev/mmcblk0p2"#g' ${BOOT}/boot/boot.cmd
        #    cat ${BOOT}/boot/boot.cmd
        #    mkimage -C none -A arm -T script -d ${BOOT}/boot/boot.cmd ${BOOT}/boot/boot.scr
        #    cat ${BOOT}/boot/boot.scr
        #fi
        
        blkid /dev/mapper/${LOOP}p1 -s UUID -o value > uuid
       
        echo "uuid:"
        cat uuid
        
        extract_root ${BOOT} ${OUTPUT}/root
        cp uuid ${OUTPUT}/root/uuid

        PTTYPE=$(fdisk -l /dev/${LOOP} | grep "Disklabel type:" | awk '{ print $3 }')
        echo $PTTYPE > ${OUTPUT}/root/pttype

        cd ${BOOT}
        ls -la
        ls | grep -v boot | grep -v uEnv.txt | xargs rm -rf
        ls -la
        cd ${BUILD_DIR}
        
        sync
        umount /dev/mapper/${LOOP}p1
        fsck -fy /dev/mapper/${LOOP}p1 || true
        BOOT_SIZE_MB=200
        resize2fs /dev/mapper/${LOOP}p1 ${BOOT_SIZE_MB}M
        pwd
        ls -la
        BOOT_SIZE_SECTORS=$((${BOOT_SIZE_MB}*1024*2))
        BOOT_PARTITION_END_SECTOR=$(($BOOT_PARTITION_START_SECTOR+$BOOT_SIZE_SECTORS))
        sync
        dmsetup remove -f /dev/mapper/${LOOP}p1
        losetup -d /dev/${LOOP}

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
    else
        echo "double partition disk"
        echo "checking ${BOOT}/cmdline.txt"
        cmdline_txt=${BOOT}/cmdline.txt
        if [[ -f ${cmdline_txt} ]]; then
            cat ${cmdline_txt}
            sed -i 's/$/ /' ${cmdline_txt}
            sed -i 's#init=.* #init=/sbin/init #g' ${cmdline_txt}
            cat ${cmdline_txt}
        fi

        umount /dev/mapper/${LOOP}p1

        sync

        dmsetup remove -f /dev/mapper/${LOOP}p1
        dmsetup remove -f /dev/mapper/${LOOP}p2
        losetup -d /dev/${LOOP}

    fi

#    rm -rf ${OUTPUT}-boot.tar.gz
#    tar czf ${OUTPUT}-boot.tar.gz $BOOT

    rm -rf ${BOOT}

fi


if [[ ${PARTITIONS} == 2 ]]; then
    echo "inspecting second partition"

    kpartx -avs ${IMAGE_FILE}| tee kpartx.out
    sync
    LOOP=loop$(cat kpartx.out | grep loop | head -1 | cut -d ' ' -f3 | cut -d p -f 2)
    rm -rf ${ROOTFS}
    mkdir -p ${ROOTFS}
    ROOTFS_LOOP=${LOOP}p2
    sync
    blkid /dev/mapper/${ROOTFS_LOOP} -s UUID -o value > uuid
    cat uuid
    blkid /dev/mapper/${ROOTFS_LOOP} -s LABEL -o value > label
    cat label
    fsck -fy /dev/mapper/${ROOTFS_LOOP} || true
    mount /dev/mapper/${ROOTFS_LOOP} ${ROOTFS}
    mount | grep ${ROOTFS}

    losetup -l
    extract_root ${ROOTFS} ${OUTPUT}/root
    cp uuid ${OUTPUT}/root
    cp label ${OUTPUT}/root

    sync
    umount /dev/mapper/${ROOTFS_LOOP}
    mount | grep ${ROOTFS} || true

    dmsetup remove -f /dev/mapper/${LOOP}p1
    dmsetup remove -f /dev/mapper/${LOOP}p2

    PTTYPE=$(fdisk -l /dev/${LOOP} | grep "Disklabel type:" | awk '{ print $3 }')
    echo $PTTYPE > ${OUTPUT}/root/pttype
    if [[ $PTTYPE == "gpt" ]]; then
      sgdisk -d 2 -g /dev/${LOOP}
    fi

    losetup -d /dev/${LOOP}

    if [[ $PTTYPE == "dos" ]]; then

echo "
d
2
w
" | fdisk ${IMAGE_FILE}
    fi

fi

echo "extracting boot partition with boot loader"

fdisk -lu ${IMAGE_FILE}

dd if=${IMAGE_FILE} of=${OUTPUT}/boot bs=1${DD_SECTOR_UNIT} count=$(( ${BOOT_PARTITION_END_SECTOR} + 100 ))

fdisk -lu ${OUTPUT}/boot

cleanup
rm -rf ${IMAGE_FILE}
echo "result: $OUTPUT"
ls -la
df -h

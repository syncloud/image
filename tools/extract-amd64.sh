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
apt install -y gdisk wget xz-utils kpartx unzip p7zip-full fdisk

IMAGE_FILE="debian-12-generic-amd64-20251112-2294.img"
IMAGE_FILE_ZIP=${IMAGE_FILE}.xz
DOWNLOAD_IMAGE="${SYNCLOUD_DISTR_URL}/${IMAGE_FILE_ZIP}"


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
        grep SQUASH ${from}/boot/config.txt || true
        cat ${from}/boot/config.txt
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

    # copy only bin files (firmware for rpi) as the rest are tool mappings such as awk (copying wrong mappings will break them)
    if [[ -d ${from}/etc/alternatives ]]; then
        find ${from} -name "cyfmac43455-sdio.bin"
        ls -la ${from}/etc/alternatives
        cp -rp ${from}/etc/alternatives/*.bin ${to}/etc || true
    fi

    if [[ -f ${from}/etc/fstab ]]; then
        cat ${from}/etc/fstab
        cp ${from}/etc/fstab ${to}/etc/fstab
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
        cat ${to}/boot/grub/grub.cfg
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
  until `wget -c --progress=dot:giga ${DOWNLOAD_IMAGE}`; do sleep 100; echo restarting; done
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
LAST_SECTOR=$(fdisk -l "$IMAGE_FILE" \
  | tr '*' ' ' \
  | awk -v img="$(basename "$IMAGE_FILE")" '$1 ~ img {print $3}' \
  | sort -n | tail -1)
SECTORS_MISSING=$(($LAST_SECTOR-$TOTAL_SECTORS+1))
if [[ "${SECTORS_MISSING}" -gt "0" ]]; then
    echo "appending missing bytes"
    dd if=/dev/zero bs=512 count=${SECTORS_MISSING} >> ${IMAGE_FILE}
fi
PARTITIONS=$(fdisk -l ${IMAGE_FILE} | grep ${IMAGE_FILE} | tail -n +2 | wc -l)
FDISK_OUTPUT=$(fdisk -l ${IMAGE_FILE} | grep ${IMAGE_FILE} | tail -n +2 | head -1)
BOOT_PARTITION_START_SECTOR=$(fdisk -l "$IMAGE_FILE" \
                              | tr '*' ' ' \
                              | awk -v img="$(basename "$IMAGE_FILE")" '$1 ~ ("^" img) {s=$2; if (s=="*") s=$3; if (s ~ /^[0-9]+$/) print s}' \
                              | sort -n | head -1)
BOOT_PARTITION_END_SECTOR=$(fdisk -l "$IMAGE_FILE" \
                            | tr '*' ' ' \
                            | awk -v img="$(basename "$IMAGE_FILE")" '$1 ~ ("^" img) {print $3}' \
                            | sort -n | uniq \
                            | tail -2 | head -1)
BOOT_PARTITION_NUMBER=$(fdisk -l $IMAGE_FILE | grep $BOOT_PARTITION_START_SECTOR | grep -oP '(?<=^'$IMAGE_FILE')\d+')
LAST_PARTITION_NUMBER=$(fdisk -l $IMAGE_FILE | grep $LAST_SECTOR | grep -oP '(?<=^'$IMAGE_FILE')\d+')
EFI_BOOT_PARTITION_NUMBER=$(fdisk -l $IMAGE_FILE | grep -i "efi system" | grep -oP '(?<=^'$IMAGE_FILE')\d+')
if [[ "$EFI_BOOT_PARTITION_NUMBER" != "" ]]; then
  BOOT_PARTITION_NUMBER=$EFI_BOOT_PARTITION_NUMBER
fi


rm -rf ${OUTPUT}
mkdir ${OUTPUT}
mkdir ${OUTPUT}/root
echo $PARTITIONS > ${OUTPUT}/root/partitions
echo $LAST_PARTITION_NUMBER > ${OUTPUT}/root/last_partition_number

echo "fixing boot"

rm -rf ${BOOT}
mkdir -p ${BOOT}
kpartx -avs ${IMAGE_FILE} | tee kpartx.out
sync
LOOP=loop$(cat kpartx.out | grep loop | head -1 | cut -d ' ' -f3 | cut -d p -f 2)
echo "LOOP: ${LOOP}"

FS_TYPE=$(blkid -s TYPE -o value /dev/mapper/${LOOP}p${BOOT_PARTITION_NUMBER})
echo "inspecting first partition"

mount /dev/mapper/${LOOP}p${BOOT_PARTITION_NUMBER} ${BOOT}

mount | grep ${BOOT}

ls -la ${BOOT}/
    
echo "multi partition disk"
echo "checking ${BOOT}/cmdline.txt"
cmdline_txt=${BOOT}/cmdline.txt
if [[ -f ${cmdline_txt} ]]; then
    cat ${cmdline_txt}
    sed -i 's/$/ /' ${cmdline_txt}
    sed -i 's#init=.* #init=/sbin/init #g' ${cmdline_txt}
    cat ${cmdline_txt}
fi
        
umount /dev/mapper/${LOOP}p${BOOT_PARTITION_NUMBER}

sync

for NUM in $(fdisk -l $IMAGE_FILE | grep -oP '(?<=^'$IMAGE_FILE')\d+'); do
  echo "unmount $NUM"
  dmsetup remove -f /dev/mapper/${LOOP}p${NUM}
done
losetup -d /dev/${LOOP}

rm -rf ${BOOT}

if [[ ${PARTITIONS} -gt 1 ]]; then
    echo "inspecting last partition"
    
    
    kpartx -avs ${IMAGE_FILE}| tee kpartx.out
    sync
    LOOP=loop$(cat kpartx.out | grep loop | head -1 | cut -d ' ' -f3 | cut -d p -f 2)
    rm -rf ${ROOTFS}
    mkdir -p ${ROOTFS}
    ROOTFS_LOOP=${LOOP}p${LAST_PARTITION_NUMBER}
    sync
    blkid /dev/mapper/${ROOTFS_LOOP} -s UUID -o value > uuid
    cat uuid
    sgdisk -i ${LAST_PARTITION_NUMBER} $IMAGE_FILE 2>/dev/null | grep "Partition GUID code" | awk -F' ' '{print $4}' | tr -d ' ' > part-type-guid
    cat part-type-guid
    sgdisk -i ${LAST_PARTITION_NUMBER} $IMAGE_FILE 2>/dev/null | grep "Partition unique GUID" | awk -F': ' '{print $2}' | tr -d ' ' > part-unique-guid
    cat part-unique-guid

    #blkid /dev/mapper/${ROOTFS_LOOP} -s LABEL -o value > label
    #cat label

    fsck -fy /dev/mapper/${ROOTFS_LOOP} || true
    mount /dev/mapper/${ROOTFS_LOOP} ${ROOTFS}
    mount | grep ${ROOTFS}

    losetup -l
    extract_root ${ROOTFS} ${OUTPUT}/root
    cp uuid ${OUTPUT}/root
    cp part-type-guid ${OUTPUT}/root
    cp part-unique-guid ${OUTPUT}/root
    #cp label ${OUTPUT}/root

    sync
    umount /dev/mapper/${ROOTFS_LOOP}
    mount | grep ${ROOTFS} || true

    for NUM in $(fdisk -l $IMAGE_FILE | grep -oP '(?<=^'$IMAGE_FILE')\d+'); do
      echo "unmount $NUM"
      dmsetup remove -f /dev/mapper/${LOOP}p${NUM}
    done

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

  IMG=${OUTPUT}/boot
  cp ${IMAGE_FILE} $IMG
  sgdisk -d $LAST_PARTITION_NUMBER $IMG
  

fdisk -lu ${OUTPUT}/boot

cleanup
rm -rf ${IMAGE_FILE}
echo "result: $OUTPUT"
ls -la
df -h


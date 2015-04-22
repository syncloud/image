#!/bin/bash

START_TIME=$(date +"%s")

BOOT_URL=https://s3-us-west-2.amazonaws.com/syncloud
BOOT_NAME=Cubian-nano+headless-x1-a20-cubietruck
BOOT_ZIP=${BOOT_NAME}.tar.gz

syncloud_image=syncloud.img

echo "installing dependencies"
sudo apt-get -y install dosfstools kpartx p7zip

if [ ! -f ${BOOT_ZIP} ]; then
  echo "getting boot"
  wget ${BOOT_URL}/${BOOT_ZIP}
else
  echo "$BOOT_ZIP is here"
fi
echo "extracting boot"
tar xzf ${BOOT_ZIP}

echo "copying boot"
cp ${BOOT_NAME}/boot ${syncloud_image}
BOOT_BYTES=$(wc -c "${syncloud_image}" | cut -f 1 -d ' ')
BOOT_SECTORS=$(( ${BOOT_BYTES} / 512 ))
echo "boot sectors: ${BOOT_SECTORS}"

DD_CHUNK_SIZE_MB=10
DD_CHUNK_COUNT=120
ROOTFS_SIZE_BYTES=$(( ${DD_CHUNK_SIZE_MB} * 1024 * 1024 * ${DD_CHUNK_COUNT} ))
echo "appending $(( ${ROOTFS_SIZE_BYTES} / 1024 / 1024 )) MB"
dd if=/dev/zero bs=${DD_CHUNK_SIZE_MB}M count=${DD_CHUNK_COUNT} >> ${syncloud_image} 
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
" | fdisk ${syncloud_image}

kpartx -a ${syncloud_image}
LOOP=$(kpartx -l ${syncloud_image} | head -1 | cut -d ' ' -f1 | cut -c1-5)
rm -rf dst
mkdir -p dst/root

mkfs.ext4 /dev/mapper/${LOOP}p2
mount /dev/mapper/${LOOP}p2 dst/root

cp -r rootfs/* dst/root/
cp -r ${BOOT_NAME}/root/* dst/root/

echo "extracting rootfs"
umount /dev/mapper/${LOOP}p2
kpartx -d ${syncloud_image}

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))

echo "Build time: $(($BUILD_TIME / 60)) min"


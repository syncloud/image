#!/bin/bash

START_TIME=$(date +"%s")

base_url=http://s3.armhf.com/dist/basefs
image_name=debian-wheezy-7.5-armhf.com-20140603

BASE_ROOTFS_ZIP=${image_name}.tar.xz
syncloud_archive=${image_name}-syncloud.tar.xz

echo "installing dependencies"
sudo apt-get -y install p7zip qemu-user-static

if [ ! -f ${BASE_ROOTFS_ZIP} ]; then
  echo "getting base rootfs"
  wget ${base_url}/${BASE_ROOTFS_ZIP}
else
  echo "$BASE_ROOTFS_ZIP is here"
fi

rm -rf rootfs
mkdir -p rootfs

echo "extracting rootfs"

tar xJf ${BASE_ROOTFS_ZIP} -C rootfs

if [[ $(uname -m) != *"arm"* ]]; then
    echo "enabling arm binary support"
    cp /usr/bin/qemu-arm-static rootfs/usr/bin/
fi

echo "disable service restart"
cp disable-service-restart.sh rootfs/root
chroot rootfs /root/disable-service-restart.sh

echo "configuring rootfs"
chroot rootfs /bin/bash -c "locale-gen en_US en_US.UTF-8"
chroot rootfs /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot rootfs /bin/bash -c "mount -t proc proc /proc"

chroot rootfs /bin/bash -c "echo \"root:syncloud\" | chpasswd"
echo "nameserver 8.8.8.8" > rootfs/run/resolvconf/resolv.conf
sed -i '/^#.*deb .*universe/s/^# *//' rootfs/etc/apt/sources.list

echo "installing ssh server"
chroot rootfs /bin/bash -c "apt-get update"
chroot rootfs /bin/bash -c "apt-get -y dist-upgrade"
chroot rootfs /bin/bash -c "apt-get -y install openssh-server"
sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" rootfs/etc/ssh/sshd_config

cp RELEASE rootfs/root
cp syncloud.sh rootfs/root
chroot rootfs /root/syncloud.sh

chroot rootfs /bin/bash -c "umount /dev/pts"
chroot rootfs /bin/bash -c "umount /proc"

echo "enable restart"
cp enable-service-restart.sh rootfs/root
chroot rootfs /root/enable-service-restart.sh

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))

echo "Build time: $(($BUILD_TIME / 60)) min"

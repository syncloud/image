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

rm -rf dst
mkdir -p dst/root

echo "extracting rootfs"

tar xJf ${BASE_ROOTFS_ZIP} -C dst/root

if [[ $(uname -m) != *"arm"* ]]; then
    echo "enabling arm binary support"
    cp /usr/bin/qemu-arm-static dst/root/usr/bin/
fi

echo "disable restart"
cat <<NOSTART > dst/root/usr/sbin/policy-rc.d
#!/bin/sh
exit 101
NOSTART
chmod +x dst/root/usr/sbin/policy-rc.d

echo "configuring rootfs"
chroot dst/root /bin/bash -c "locale-gen en_US en_US.UTF-8"
chroot dst/root /bin/bash -c "mount -t devpts devpts /dev/pts"

chroot dst/root /bin/bash -c "echo \"root:syncloud\" | chpasswd"
echo "nameserver 8.8.8.8" > dst/root/run/resolvconf/resolv.conf
sed -i '/^#.*deb .*universe/s/^# *//' dst/root/etc/apt/sources.list

echo "installing ssh server"
chroot dst/root /bin/bash -c "apt-get update"
chroot dst/root /bin/bash -c "apt-get -y dist-upgrade"
chroot dst/root /bin/bash -c "apt-get -y install openssh-server"
sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" dst/root/etc/ssh/sshd_config

chroot dst/root /bin/bash -c "umount /dev/pts"
echo "enable restart"
rm dst/root/usr/sbin/policy-rc.d

FINISH_TIME=$(date +"%s")
BUILD_TIME=$(($FINISH_TIME-$START_TIME))

echo "Build time: $(($BUILD_TIME / 60)) min"

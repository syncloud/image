#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 distro"
    exit 1
fi

DISTRO=$1

if [[ ${DISTRO} == "raspbian" ]]; then
    REPO=http://archive.raspbian.com/raspbian
    KEY=http://archive.raspbian.org/raspbian.public.key
    DEBOOTSTRAP_ARCH=armhf
    ARCH=armv7l
elif [[ ${DISTRO} == "debian" ]]; then
    REPO=http://http.debian.net/debian
    KEY=https://ftp-master.debian.org/keys/archive-key-8.asc
    DEBOOTSTRAP_ARCH=armhf
    ARCH=armv7l
elif [[ ${DISTRO} == "amd64" ]]; then
    REPO=http://http.debian.net/debian
    KEY=https://ftp-master.debian.org/keys/archive-key-8.asc
    DEBOOTSTRAP_ARCH=amd64
    ARCH=x86_64
else
    echo "${DISTRO} is not supported"
    exit 1
fi

echo "Open file limit: $(ulimit -n)"

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

apt-get update
apt-get -y install debootstrap qemu-user-static lsof

ROOTFS=${DIR}/rootfs

function cleanup {

    mount | grep rootfs
    mount | grep rootfs | awk '{print "umounting "$1; system("umount "$3)}'
    mount | grep rootfs

    echo "killing chroot services"
    lsof 2>&1 | grep rootfs | grep -v java | awk '{print $1 $2}' | sort | uniq
    lsof 2>&1 | grep rootfs | grep -v java | awk '{print $2}' | sort | uniq | xargs kill -9
    echo "chroot services after kill"
    lsof 2>&1 | grep rootfs
}

cleanup

rm -rf ${ROOTFS}
rm -rf rootfs.tar.gz

qemu-debootstrap --no-check-gpg --include=ca-certificates,locales --arch=${DEBOOTSTRAP_ARCH} jessie ${ROOTFS} ${REPO}

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' ${ROOTFS}/etc/locale.gen
chroot ${ROOTFS} /bin/bash -c "locale-gen en_US en_US.UTF-8"

echo "disable service restart"
cp disable-service-restart.sh ${ROOTFS}/root
chroot ${ROOTFS} /root/disable-service-restart.sh

chroot ${ROOTFS} wget ${KEY} -O archive.key
chroot ${ROOTFS} apt-key add archive.key

chroot ${ROOTFS} /bin/bash -c "echo \"root:syncloud\" | chpasswd"
chroot ${ROOTFS} /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot ${ROOTFS} /bin/bash -c "mount -t proc proc /proc"

echo "copy system files to get image working"
if [ -d ${DISTRO} ]; then
    cp -rf ${DISTRO}/* ${ROOTFS}/
fi

chroot ${ROOTFS} apt-get update
chroot ${ROOTFS} apt-get -y dist-upgrade
chroot ${ROOTFS} apt-get -y install sudo openssh-server wget less parted lsb-release unzip bzip2 curl dbus avahi-daemon ntp
chroot ${ROOTFS} ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
chroot ${ROOTFS} /bin/bash -c "cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys"
sed -i -e'/AVAHI_DAEMON_DETECT_LOCAL/s/1/0/' ${ROOTFS}/etc/default/avahi-daemon
sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" ${ROOTFS}/etc/ssh/sshd_config

echo "copy system files again as some packages might have replaced our files"
if [ -d ${DISTRO} ]; then
    cp -rf ${DISTRO}/* ${ROOTFS}/
fi
mkdir ${ROOTFS}/opt/data
mkdir ${ROOTFS}/opt/app

echo "enable restart"
cp enable-service-restart.sh ${ROOTFS}/root
chroot ${ROOTFS} /root/enable-service-restart.sh

cleanup

echo "cleaning apt cache"
rm -rf ${ROOTFS}/var/cache/apt/archives/*.deb

echo "zipping bootstrap"
tar czf rootfs.tar.gz -C ${ROOTFS} .
#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 distro"
    exit 1
fi

DISTRO=$1

if [[ ${DISTRO} == "raspbian" ]]; then
    REPO=http://archive.raspbian.com/raspbian
    KEY=http://archive.raspbian.org/raspbian.public.key
    ARCH=armhf
elif [[ ${DISTRO} == "debian" ]]; then
    REPO=http://http.debian.net/debian
    KEY=https://ftp-master.debian.org/keys/archive-key-8.asc
    ARCH=armhf
elif [[ ${DISTRO} == "amd64" ]]; then
    REPO=http://http.debian.net/debian
    KEY=https://ftp-master.debian.org/keys/archive-key-8.asc
    ARCH=amd64
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

apt-get -y install debootstrap qemu-user-static

function cleanup {

    mount | grep rootfs
    mount | grep rootfs | awk '{print "umounting "$1; system("umount "$3)}'
    mount | grep rootfs

    echo "killing chroot services"
    lsof | grep rootfs | grep -v java | awk '{print $1 $2}' | sort | uniq
    lsof | grep rootfs | grep -v java | awk '{print $2}' | sort | uniq | xargs kill -9
    echo "chroot services after kill"
    lsof | grep rootfs
}

cleanup

rm -rf rootfs
rm -rf rootfs.tar.gz

qemu-debootstrap --no-check-gpg --include=ca-certificates,locales --arch=${ARCH} jessie rootfs ${REPO}

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' rootfs/etc/locale.gen
chroot rootfs /bin/bash -c "locale-gen en_US en_US.UTF-8"

echo "disable service restart"
cp disable-service-restart.sh rootfs/root
chroot rootfs /root/disable-service-restart.sh

chroot rootfs wget ${KEY} -O archive.key
chroot rootfs apt-key add archive.key

chroot rootfs /bin/bash -c "echo \"root:syncloud\" | chpasswd"
chroot rootfs /bin/bash -c "mount -t devpts devpts /dev/pts"
chroot rootfs /bin/bash -c "mount -t proc proc /proc"

echo "copy system files to get image working"
if [ -d ${DISTRO} ]; then
    cp -rf ${DISTRO}/* rootfs/
fi

chroot rootfs apt-get update
chroot rootfs apt-get -y dist-upgrade
chroot rootfs /bin/bash -c "echo 'mysql-server-5.5 mysql-server/root_password password root' | debconf-set-selections"
chroot rootfs /bin/bash -c "echo 'mysql-server-5.5 mysql-server/root_password_again password root' | debconf-set-selections"
chroot rootfs /bin/bash -c "echo 'slapd/root_password password syncloud' | debconf-set-selections"
chroot rootfs /bin/bash -c "echo 'slapd/root_password_again password syncloud' | debconf-set-selections"
chroot rootfs apt-get -y install sudo openssh-server python-dev gcc wget less bootlogd parted lsb-release unzip bzip2\
 mysql-server libmysqlclient-dev ldap-utils slapd libldap2-dev libsasl2-dev libssl-dev curl dbus avahi-daemon \
 miniupnpc ntp udisks-glue libpq-dev

wget --no-check-certificate --progress=dot:mega -O rootfs/root/get-pip.py https://bootstrap.pypa.io/get-pip.py 2>&1
chroot rootfs python root/get-pip.py

sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" rootfs/etc/ssh/sshd_config

echo "copy system files again as some packages might have replaced our files"
if [ -d ${DISTRO} ]; then
    cp -rf ${DISTRO}/* rootfs/
fi
mkdir rootfs/opt/data
mkdir rootfs/opt/app

echo "enable restart"
cp enable-service-restart.sh rootfs/root
chroot rootfs /root/enable-service-restart.sh

cleanup

echo "cleaning apt cache"
rm -rf rootfs/var/cache/apt/archives/*.deb

echo "zipping bootstrap"
tar czf rootfs.tar.gz rootfs
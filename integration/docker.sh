#!/usr/bin/env bash

ROOTFS=/tmp/rootfs
APP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd ${APP_DIR}
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ARCH=$(dpkg-architecture -q DEB_HOST_GNU_CPU)

if [ ! -f 3rdparty/rootfs-${ARCH}.tar.gz ]; then
  mkdir 3rdparty
  wget http://build.syncloud.org:8111/guestAuth/repository/download/debian_rootfs_syncloud_${ARCH}/lastSuccessful/rootfs.tar.gz\
  -O 3rdparty/rootfs-${ARCH}.tar.gz --progress dot:giga
else
  echo "skipping rootfs"
fi

apt-get install docker.io
service docker start

function cleanup {

    echo "cleaning old rootfs"
    rm -rf /tmp/rootfs

    echo "docker images"
    docker images -q

    echo "removing images"
    docker rm $(docker kill $(docker ps -qa))
    docker rmi $(docker images -q)

    echo "docker images"
    docker images -q
}

cleanup

rm -rf ${ROOTFS}
mkdir -p ${ROOTFS}

echo "extracting rootfs"
tar xzf ${APP_DIR}/3rdparty/rootfs-${ARCH}.tar.gz -C ${ROOTFS}

#echo "rootfs version: $(<rootfs/version)"
sed -i 's/Port 22/Port 2222/g' ${ROOTFS}/etc/ssh/sshd_config
mkdir ${ROOTFS}/test

echo "copying all files to rootfs"
rsync -a ${APP_DIR}/ ${ROOTFS}/test --exclude=/3rdparty

echo "importing rootfs"
tar -C ${ROOTFS} -c . | docker import - syncloud

echo "starting rootfs"
docker run --net host -v /var/run/dbus:/var/run/dbus --name rootfs --privileged -d -it syncloud /sbin/init

ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:2222

echo "sleeping for services to start"
sleep 10
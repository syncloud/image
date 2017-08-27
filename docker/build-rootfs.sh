#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [ -z "$1" ]; then
    echo "usage: $0 arch"
    exit 1
fi

ARCH=$1
apt-get install debootstrap
${DIR}/../bootstrap/bootstrap.sh
cat rootfs-$(dpkg --print-architecture).tar.gz | docker import - syncloud/rootfs-${ARCH}
docker push syncloud/rootfs-${ARCH}

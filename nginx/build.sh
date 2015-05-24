#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

export TMPDIR=/tmp
export TMP=/tmp
VERSION=1.8.0
ROOT=/opt/syncloud-platform
PREFIX=${ROOT}/nginx

apt-get -y install build-essential flex bison libreadline-dev zlib1g-dev libpcre3-dev
rm -rf nginx-${VERSION}.tar.gz*
wget http://nginx.org/download/nginx-${VERSION}.tar.gz
tar xzf nginx-${VERSION}.tar.gz
cd nginx-${VERSION}
./configure --prefix=${PREFIX}
make
rm -rf ${PREFIX}
make install
cd ..
rm -rf nginx-${VERSION}.tar.gz*
tar czf nginx-${VERSION}.tar.gz -C ${ROOT} nginx

#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

export TMPDIR=/tmp
export TMP=/tmp
NAME=postgresql
VERSION=9.4.2
ROOT=/opt/syncloud-platform
PREFIX=${ROOT}/postgresql

apt-get -y install build-essential flex bison libreadline-dev zlib1g-dev

rm -rf build
mkdir -p build
cd build

wget https://ftp.postgresql.org/pub/source/v${VERSION}/${NAME}-${VERSION}.tar.bz2
tar xjf ${NAME}-${VERSION}.tar.bz2
cd ${NAME}-${VERSION}
./configure --prefix ${PREFIX}
make
rm -rf ${PREFIX}
make install
cd ..
tar czf ${NAME}-${VERSION}.tar.gz -C ${ROOT} ${NAME}

cd ..
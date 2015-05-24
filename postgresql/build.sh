#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

export TMPDIR=/tmp
export TMP=/tmp
VERSION=9.4.2

apt-get -y install build-essential flex bison libreadline-dev zlib1g-dev
rm -rf postgresql-${VERSION}.tar.bz2*
wget https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.bz2
tar xjf postgresql-${VERSION}.tar.bz2
cd postgresql-${VERSION}
./configure --prefix /opt/postgresql
make
rm -rf /opt/postgresql
make install
cd ..
tar czf postgresql-${VERSION}.tar.gz -C /opt postgresql

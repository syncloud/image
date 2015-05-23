#!/bin/bash
wget https://ftp.postgresql.org/pub/source/v9.4.2/postgresql-9.4.2.tar.bz2
tar xjvf postgresql-9.4.2.tar.bz2
cd postgresql
./configure --prefix /opt/postgresql
make
rm -rf /opt/postgresql
make install
cd ..
tar czvf postgresql-9.4.2.tar.gz -C /opt postgresql

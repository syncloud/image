#!/bin/bash -x

apt-get -y remove owncloud
rm -rf /var/www/owncloud
rm -rf /data/owncloud
rm -rf /etc/owncloud
apt-get -y purge mysql-common mysql-server-5.5
rm -rf /var/lib/mysql
rm -rf /data/mysql
rm -rf /etc/mysql
apt-get -y autoremove

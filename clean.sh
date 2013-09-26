#!/bin/bash -x

apt-get -y remove owncloud
rm -rf /var/www/owncloud
apt-get -y remove mysql-server mysql-client mysql-common
sudo rm -rf /var/lib/mysql
apt-get -y autoremove

#!/bin/bash -x

OWNCLOUDPATH='/var/www/owncloud'

# PHP-Accelerator
apt-get -y install php-apc

# install mySql (set root user password to root)
debconf-set-selections mysql-root.txt
apt-get -y install mysql-server-5.5

# create MySQL database and user/password
mysql -uroot -proot < mysql.sql

# install owncloud
wget --no-check-certificate http://download.opensuse.org/repositories/isv:ownCloud:community/Debian_7.0/Release.key
apt-key add - < Release.key
rm Release.key
cp owncloud.list /etc/apt/sources.list.d/owncloud.list
apt-get update
apt-get -y install owncloud

# change ownership of /data folder
chown -R www-data:www-data /data

# disable some owncloud apps
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/contacts/appinfo/info.xml
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/calendar/appinfo/info.xml

# hardcode data folder and database connections
wget --no-check-certificate https://github.com/syncloud/owncloud-core/raw/master/core/templates/installation.php
cp installation.php $OWNCLOUDPATH/core/templates/installation.php
rm installation.php

# setup cron jobs
# mysql -uroot -proot < cron.sql

# crontab -u www-data -e
su -c "echo \"*/1 * * * * php -f ${OWNCLOUDPATH}/cron.php\" | crontab -" www-data

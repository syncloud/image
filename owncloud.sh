#!/bin/bash -x

OWNCLOUDPATH='/var/www/owncloud'

# Tools
apt-get -y install php-apc miniupnpc

# install mySql (set root user password to root)
echo "mysql-server-5.5 mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password root" | debconf-set-selections
apt-get -y install mysql-server-5.5

# move mysql data folder
service mysql stop
cp -R -p /var/lib/mysql /data/mysql
sed "s/datadir.*/datadir\t\t= \/data\/mysql/g" -i /etc/mysql/my.cnf

#fixing apparmor if exist
mysq_apparmor=/etc/apparmor.d/usr.sbin.mysqld
if [ -e "$mysq_apparmor" ]
then
  echo "fixing mysql apparmor: $mysq_apparmor"
  sed "s/\/var\/lib\/mysql/\/data\/mysql/g" -i $mysq_apparmor
fi

service mysql start

# create MySQL database and user/password
mysql -uroot -proot <<EOFMYSQL
CREATE USER 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';
CREATE DATABASE IF NOT EXISTS owncloud;
GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';
EOFMYSQL

# install owncloud
owncloud_repo=http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_12.10
wget --no-check-certificate -qO - $owncloud_repo/Release.key | apt-key add -
echo "deb $owncloud_repo/ /" > /etc/apt/sources.list.d/owncloud.list
apt-get update
apt-get -y --no-install-recommends install owncloud

# allow htaccess files
#sed "s/AllowOverride.*/AllowOverride All/g" -i /etc/apache2/sites-available/default
service apache2 reload

# change ownership of owncloud data folder
mkdir /data/owncloud
chown -R www-data:www-data /data/owncloud

# disable some owncloud apps
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/contacts/appinfo/info.xml
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/calendar/appinfo/info.xml
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/updater/appinfo/info.xml

# hardcode data folder and database connections
# wget --no-check-certificate -O $OWNCLOUDPATH/core/templates/installation.php https://github.com/syncloud/owncloud-core/raw/master/core/templates/installation.php
# wget --no-check-certificate -O $OWNCLOUDPATH/core/setup.php https://github.com/syncloud/owncloud-core/raw/master/core/setup.php

# setup crontab task
su -c "echo \"*/1 * * * * php -f ${OWNCLOUDPATH}/cron.php\" | crontab -" www-data

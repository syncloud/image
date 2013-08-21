# update packages
apt-get update

# fix mac address
-> get mac address by ifconfig locate eth0 HWaddr
cd /boot
nano script.fex
--> add following text to the end
--> [dynamic]
--> MAC = "MAC ADDRESS"
fex2bin script.fex script.bin

# install disk
cd /
mkdir data
--> modify /etc/fstab - add /dev/sda1 to /data

# PHP-Accelerator
apt-get install php-apc

# install mySql (set root user password to root)
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password root'
apt-get -y install mysql-server-5.5

# create mySql database (owncloud) and user (owncloud) with password (owncloud)
mysql -uroot -proot < setup.sql
--> where setup.sql is following:
CREATE USER 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';
CREATE DATABASE IF NOT EXISTS owncloud;
GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';

# install owncloud
wget http://download.opensuse.org/repositories/isv:ownCloud:community/Debian_7.0/Release.key
apt-key add - < Release.key
rm Release.key
echo 'deb http://download.opensuse.org/repositories/isv:ownCloud:community/Debian_7.0/ /' >> /etc/apt/sources.list.d/owncloud.list
apt-get update
apt-get install owncloud

# change ownership of /data folder
chown -R www-data:www-data /data

# disable some owncloud apps
sed -i -e "/<default_enable\/>/d" /usr/share/owncloud/apps/contacts/appinfo/info.xml
sed -i -e "/<default_enable\/>/d" /usr/share/owncloud/apps/calendar/appinfo/info.xml

# hardcode data folder and database connections
wget https://github.com/syncloud/core/raw/master/core/templates/installation.php
cp installation.php /usr/share/owncloud/core/templates/installation.php
rm installation.php

# setup cron jobs
mysql -uroot -proot < backgorundjobs.sql
--> where backgorundjobs.sql is following
USE owncloud
INSERT INTO `owncloud`.`oc_appconfig`(`appid`, `configkey`, `configvalue`)
VALUES ('core', 'backgroundjobs_mode', 'cron');

crontab -u www-data -e
--> */1 * * * * php -f /var/www/owncloud/cron.php


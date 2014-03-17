#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

HOSTNAME=$(uname -n)

BOOT_SCRIPT_NAME=/usr/local/bin/syncloud_boot.sh

rm -rf $BOOT_SCRIPT_NAME
cp syncloud_boot.templ $BOOT_SCRIPT_NAME
chmod +x $BOOT_SCRIPT_NAME

# if this is cubieboard we need to fix few things before installing ownCloud
if [[ $HOSTNAME = "cubieboard" ]]; then
    # fix locale warnings
    locale-gen en_US.UTF-8

    # update packages
    apt-get -y update

    # we don't need mysql - owncloud script should install and configure it
    apt-get -y remove --purge mysql-server mysql-client mysql-common
    apt-get -y autoremove
    apt-get -y autoclean
    rm -rf /var/lib/mysql
    rm -rf /var/log/mysql
    
    # install script for setting mac address
    cp setmacaddr.sh /usr/local/bin/setmacaddr.sh

    # add setting mac address to the rc.local
    echo "/usr/local/bin/setmacaddr.sh" >> $BOOT_SCRIPT_NAME
fi

VERSION_TO_INSTALL='latest' #[latest|appstore] 
DATADIR=/data
OWNCLOUDPATH='/var/www/owncloud'

apt-get -y install lsb-release

OS_VERSION=$(lsb_release -sr)
OS_ID=$(lsb_release -si)

if [[ $OS_ID = "Debian" ]]; then
  sed -i 's/wheezy/jessie/g' /etc/apt/sources.list
  echo "libc6 libraries/restart-without-asking boolean true" | debconf-set-selections
  echo "libc6:armhf libraries/restart-without-asking boolean true" | debconf-set-selections
fi

apt-get -y update

# create data folder
mkdir $DATADIR

# copy tool for mounting hdd
cp mounthdd.py /usr/local/bin/mounthdd.py

# generate script mounting hdd to DATADIR
python substitute.py mounthdd.templ /usr/local/bin/mounthdd.sh DATADIR=$DATADIR
chmod +x /usr/local/bin/mounthdd.sh

# add mounting DATADIR script to boot script
echo "/usr/local/bin/mounthdd.sh" >> $BOOT_SCRIPT_NAME

# generate script for setting DATADIR permissions
python substitute.py setdataperm.templ /usr/local/bin/setdataperm.sh DATADIR=$DATADIR
chmod +x /usr/local/bin/setdataperm.sh

# add DATADIR permissions script boot script
echo "/usr/local/bin/setdataperm.sh" >> $BOOT_SCRIPT_NAME

# mount data folder
/usr/local/bin/mounthdd.sh

# change permissions of data folder
/usr/local/bin/setdataperm.sh

# tools for owncloud
apt-get -y install php-apc miniupnpc

apt-get -y install avahi-daemon

if grep -q inet /etc/group; then
    # add user avahi to inet group
    usermod -a -G inet avahi
fi

# install mySQL (set root user password to root)
echo "mysql-server-5.5 mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password root" | debconf-set-selections
apt-get -y install mysql-server-5.5 unzip

if grep -q inet /etc/group; then
    # add mysql user to inet group
    usermod -a -G inet mysql
fi

# create mySQL database and user/password
mysql -uroot -proot <<EOFMYSQL
CREATE USER 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';
CREATE DATABASE IF NOT EXISTS owncloud;
GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';
EOFMYSQL

# install owncloud
if [[ $OS_VERSION = "13.06" ]]; then OS_VERSION="13.04"; fi # fix for cubieboard lubuntu 13.06

if [[ $OS_ID = "Debian" ]]; then
    owncloud_repo=http://download.opensuse.org/repositories/isv:ownCloud:community/Debian_7.0
else
    owncloud_repo=http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_$OS_VERSION
fi

wget --no-check-certificate -qO - $owncloud_repo/Release.key | apt-key add -
echo "deb $owncloud_repo/ /" > /etc/apt/sources.list.d/owncloud.list

cat <<APTPREF > /etc/apt/preferences
Package: *
Pin: origin download.opensuse.org
Pin-Priority: 610
APTPREF

apt-get update
apt-get -y --no-install-recommends install owncloud

if grep -q inet /etc/group; then
    # add www-data user to inet group
    usermod -a -G inet www-data
fi

if [[ $OS_VERSION = "13.10" ]]; then 
   
cat <<APACHE > /etc/apache2/sites-available/owncloud.conf
<Directory /var/www/owncloud>
  AllowOverride All
</Directory>
APACHE

a2ensite owncloud

fi

if [[ $OS_ID = "Debian" ]]; then 
  echo "Alias /owncloud /var/www/owncloud" > /etc/apache2/sites-available/owncloud.conf
  a2ensite owncloud
fi

# disable some owncloud apps
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/contacts/appinfo/info.xml
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/calendar/appinfo/info.xml
sed -i -e "/<default_enable\/>/d" $OWNCLOUDPATH/apps/updater/appinfo/info.xml

cat <<AUTOCNF > $OWNCLOUDPATH/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "mysql", 
  "dbname"        => "owncloud",
  "dbuser"        => "root",
  "dbpass"        => "root",
  "dbhost"        => "localhost",
  "directory"     => "$DATADIR",
);
AUTOCNF

# setup crontab task
su -c "echo \"*/1 * * * * php -f ${OWNCLOUDPATH}/cron.php\" | crontab -" www-data

cd $OWNCLOUDPATH/apps

wget -qO- https://raw.github.com/syncloud/upnp_port_mapper/master/get_$VERSION_TO_INSTALL.sh | sh
   
sed -i '/<info>/a \<default_enable\/>' ./upnp_port_mapper/appinfo/info.xml
sed -i '/<info>/a \<default_native\/>' ./upnp_port_mapper/appinfo/info.xml
sed -i '/<info>/a \<default_mapped\/>' ./upnp_port_mapper/appinfo/info.xml

service apache2 reload

# service discovery through avahi

cat <<AVAHI > /etc/avahi/services/owncloud.service
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Owncloud on %h</name>
  <service>
    <type>_http._tcp</type>
    <port>80</port>
    <txt-record>path=/owncloud</txt-record>
  </service>
</service-group>
AVAHI

service avahi-daemon restart

# add boot script to rc.local
sed -i '/# By default this script does nothing./a /usr/local/bin/syncloud_boot.sh' /etc/rc.local


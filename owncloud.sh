#!/bin/bash -x

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

VERSION_TO_INSTALL='latest' #[latest|appstore] 
DATADIR=/data
OWNCLOUDPATH='/var/www/owncloud'

apt-get -y update

# create data folder
mkdir $DATADIR

# mount HDD
mount /dev/sda1 $DATADIR

# add fstab mapping for HDD
sed -i '$ a\/dev/sda1 /data ext4 defaults 0 0' /etc/fstab

# generate script for setting DATADIR permissions
cat > /usr/local/bin/setdataperm.sh <<TAGSETDATAPERM
#!/bin/bash
chmod 770 $DATADIR
chown -R www-data:www-data $DATADIR
TAGSETDATAPERM

chmod +x /usr/local/bin/setdataperm.sh

# add DATADIR permissions script to rc.local
sed -i '/# By default this script does nothing./a /usr/local/bin/setdataperm.sh' /etc/rc.local

# change permissions of data folder
/usr/local/bin/setdataperm.sh

# tools for owncloud
apt-get -y install php-apc miniupnpc lsb-release avahi-daemon

# install mySQL (set root user password to root)
echo "mysql-server-5.5 mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password root" | debconf-set-selections
apt-get -y install mysql-server-5.5 unzip

# create mySQL database and user/password
mysql -uroot -proot <<EOFMYSQL
CREATE USER 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';
CREATE DATABASE IF NOT EXISTS owncloud;
GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY 'owncloud';
EOFMYSQL

# install owncloud
OS_VERSION=$(lsb_release -sr)
OS_ID=$(lsb_release -si)
if [[ $OS_VERSION = "13.06" ]]; then OS_VERSION="13.04"; fi # fix for cubieboard lubuntu 13.06

if [[ $OS_ID = "Debian" ]]; then
owncloud_repo=http://download.opensuse.org/repositories/isv:ownCloud:community/Debian_7.0
else
owncloud_repo=http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_$OS_VERSION
fi

wget --no-check-certificate -qO - $owncloud_repo/Release.key | apt-key add -
echo "deb $owncloud_repo/ /" > /etc/apt/sources.list.d/owncloud.list
apt-get update
apt-get -y --no-install-recommends install owncloud
apt-get -y remove libapache2-mod-php5filter

#fix owncloud warning for 13.10
if [[ $OS_VERSION = "13.10" ]]; then 
   
cat <<APACHE > /etc/apache2/sites-available/owncloud.conf
<Directory /var/www/owncloud>
  AllowOverride All
</Directory>
APACHE

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

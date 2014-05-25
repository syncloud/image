#!/bin/bash +x

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

HOSTNAME=$(uname -n)
SYNCLOUD_CONF_PATH=/etc/syncloud
SYNCLOUD_TOOLS_PATH=/usr/local/bin/syncloud
cp -r tools $SYNCLOUD_TOOLS_PATH

BOOT_SCRIPT_NAME=$SYNCLOUD_TOOLS_PATH/boot.sh

rm -rf $BOOT_SCRIPT_NAME
cp boot.templ $BOOT_SCRIPT_NAME
chmod +x $BOOT_SCRIPT_NAME

mkdir $SYNCLOUD_CONF_PATH
cp version $SYNCLOUD_CONF_PATH

# update packages
apt-get -y update

# if this is Cubian we need to fix few things before installing ownCloud
if [[ $HOSTNAME = "Cubian" ]]; then
    # fix locale warnings
    locale-gen en_US.UTF-8
fi

# if this is cubieboard we need to fix few things before installing ownCloud
if [[ $HOSTNAME = "cubieboard" ]]; then
    # fix locale warnings
    locale-gen en_US.UTF-8

    # we don't need mysql - owncloud script should install and configure it
    apt-get -y remove --purge mysql-server mysql-client mysql-common
    apt-get -y autoremove
    apt-get -y autoclean
    rm -rf /var/lib/mysql
    rm -rf /var/log/mysql
    
    # add setting mac address to the rc.local
    echo "$SYNCLOUD_TOOLS_PATH/setmacaddr.sh" >> $BOOT_SCRIPT_NAME
elif [[ $HOSTNAME = "arm"  ]]; then
  sed -i '/^check_running_system$/i umount /data || true' /opt/scripts/tools/beaglebone-black-eMMC-flasher.sh
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

  if [ -e /etc/profile.d/raspi-config.sh ]; then
    rm -f /etc/profile.d/raspi-config.sh
    sed -i /etc/inittab \
      -e "s/^#\(.*\)#\s*RPICFG_TO_ENABLE\s*/\1/" \
      -e "/#\s*RPICFG_TO_DISABLE/d"
    telinit q
  fi

fi

apt-get -y update

# create data folder
mkdir $DATADIR

# command: mount hdd to DATADIR
CMD_MOUNTHDD="python $SYNCLOUD_TOOLS_PATH/mounthdd.py $DATADIR"

# add mounting DATADIR script to boot script
echo "$CMD_MOUNTHDD" >> $BOOT_SCRIPT_NAME

# command: set permissions for www user to DATADIR  
CMD_WWWDATAFOLDER="$SYNCLOUD_TOOLS_PATH/wwwdatafolder.sh $DATADIR"

# add DATADIR permissions script boot script
echo "$CMD_WWWDATAFOLDER" >> $BOOT_SCRIPT_NAME

# mount and set permissions to data folder
$CMD_MOUNTHDD
$CMD_WWWDATAFOLDER

apt-get -y install miniupnpc ntp ntpdate

# install avahi
apt-get -y install avahi-daemon

if grep -q inet /etc/group; then
    # add user avahi to inet group
    usermod -a -G inet avahi
fi

# service discovery through avahi

AVAHI_CONFIG=/etc/avahi/services/owncloud.service

cat <<AVAHI > $AVAHI_CONFIG
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name>ownCloud</name>
  <service>
    <type>_http._tcp</type>
    <port>80</port>
    <txt-record>path=/owncloud</txt-record>
  </service>
</service-group>
AVAHI

chmod 644 $AVAHI_CONFIG

sed 's/AVAHI_DAEMON_DETECT_LOCAL=.*/AVAHI_DAEMON_DETECT_LOCAL=0/g' -i /etc/default/avahi-daemon

service avahi-daemon restart

# add boot script to rc.local
sed -i '/# By default this script does nothing./a '$BOOT_SCRIPT_NAME /etc/rc.local

echo "root:syncloud" | chpasswd

wget -qO- https://raw.githubusercontent.com/syncloud/apps/master/spm | bash -s install
/opt/syncloud/repo/system/spm install owncloud




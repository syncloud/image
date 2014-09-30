#!/bin/bash -x

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -x
# export SHELLOPTS

#Fix debconf frontend warnings
DEBCONF_FRONTEND=noninteractive

# enable "do not start on install" policy
cat <<NOSTART > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
NOSTART
chmod +x /usr/sbin/policy-rc.d

# update packages
apt-get -y update

# indentifying OS name and version
apt-get -y install lsb-release
OS_VERSION=$(lsb_release -sr)
OS_ID=$(lsb_release -si)

# use jessie and supress libc6 upgrade interractive questions on debian
if [[ $OS_ID = "Debian" ]]; then
  sed -i 's/wheezy/jessie/g' /etc/apt/sources.list
  echo "libc6 libraries/restart-without-asking boolean true" | debconf-set-selections
  echo "libc6:armhf libraries/restart-without-asking boolean true" | debconf-set-selections

  # disable pi interractive config
  if [ -e /etc/profile.d/raspi-config.sh ]; then
    rm -f /etc/profile.d/raspi-config.sh
    sed -i /etc/inittab \
      -e "s/^#\(.*\)#\s*RPICFG_TO_ENABLE\s*/\1/" \
      -e "/#\s*RPICFG_TO_DISABLE/d"
    telinit q
  fi
fi

apt-get -y update
apt-get -yf install
apt-get -y install build-essential python python-dev

# install pip2 used for syncloud apps installation
if ! type pip2; then
  wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py
  python get-pip.py
  hash -r
fi


wget -qO- https://raw.githubusercontent.com/syncloud/apps/0.7/sam | bash -s install
sam install image-base
sam install image-boot
sam install insider
sam install owncloud
sam install owncloud-ctl
sam install discovery
sam install remote-access

# disable "do not start on install" policy
rm /usr/sbin/policy-rc.d


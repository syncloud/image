#!/bin/bash -x

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -x
# export SHELLOPTS

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

# enable "do not start on install" policy
cat <<NOSTART > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
NOSTART
chmod +x /usr/sbin/policy-rc.d

####### sam bootstrap #######

apt-get -y install python wget

# install pip2 used for syncloud apps installation
if ! type pip2; then
  wget --progress=dot:mega -O get-pip.py https://bootstrap.pypa.io/get-pip.py
  python get-pip.py
  hash -r
fi

wget -qO- https://raw.githubusercontent.com/syncloud/apps/0.7/sam | bash -s install

####### sam bootstrap #######

sam --debug install image-base
sam --debug install image-boot
sam install insider
sam --debug install owncloud
sam install owncloud-ctl
sam install discovery
sam install remote-access

# disable "do not start on install" policy
rm /usr/sbin/policy-rc.d


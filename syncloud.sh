#!/bin/bash -x

echo "Running from: $PWD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -x
#export SHELLOPTS

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

wget -qO- https://raw.githubusercontent.com/syncloud/apps/0.7/sam | bash -s bootstrap

sam --debug install image-base
sam --debug install image-boot
sam install insider
sam --debug install owncloud
sam install owncloud-ctl
sam install discovery
sam install remote-access
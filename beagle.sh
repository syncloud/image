#!/bin/bash

if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root" 1>&2
   exit 1
fi

mkdir /data

wget -qO- https://raw.github.com/syncloud/owncloud-setup/internal_mysql/owncloud.sh | sudo bash

sed -i '/debugfs.*fstab/a \\techo "/dev/sda1 /data auto defaults 0 0" >> /tmp/rootfs/etc/fstab' /opt/scripts/tools/beaglebone-black-eMMC-flasher.sh
/opt/scripts/tools/beaglebone-black-eMMC-flasher.sh

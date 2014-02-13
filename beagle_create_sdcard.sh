#!/bin/bash

if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root" 1>&2
   exit 1
fi

wget -qO- https://raw.github.com/syncloud/owncloud-setup/master/owncloud.sh | sudo bash

sed -i '/debugfs.*fstab/a \\techo "/dev/sda1 /data ext4 defaults 0 0" >> /tmp/rootfs/etc/fstab' /opt/scripts/tools/beaglebone-black-eMMC-flasher.sh
wget -qO- https://raw.github.com/RobertCNelson/tools/master/scripts/beaglebone-black-make-microSD-flasher-from-eMMC.sh | sudo bash

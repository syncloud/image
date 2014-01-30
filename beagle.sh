#!/bin/bash

if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root" 1>&2
   exit 1
fi

mkdir /data

wget -qO- https://raw.github.com/syncloud/owncloud-setup/master/owncloud.sh | sudo bash


wget -qO- https://raw.github.com/RobertCNelson/tools/master/scripts/beaglebone-black-make-microSD-flasher-from-eMMC.sh | sudo bash


#cd /opt/scripts/tools
#wget https://raw.github.com/RobertCNelson/tools/master/scripts/beaglebone-black-make-microSD-flasher-from-eMMC.sh 
#sed -i '/debugfs.*fstab/a \\techo "/dev/sda1 /data auto defaults 0 0" >> /tmp/rootfs/etc/fstab' beaglebone-black-make-microSD-flasher-from-eMMC.sh
#chmod +x beaglebone-black-make-microSD-flasher-from-eMMC.sh
#./beaglebone-black-make-microSD-flasher-from-eMMC.sh

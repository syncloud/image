#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# update packages
apt-get update

# generate script for setting mac address
cat > /usr/local/bin/setmacaddr.sh <<"TAGSETMACADDRESS"
#!/bin/bash
SET_MAC_ADDR_LOG="/var/log/setmacaddr.log"
if [ ! -f $SET_MAC_ADDR_LOG ]; then
    WORKING_FOLDER=/tmp/setmacaddr
    mkdir $WORKING_FOLDER
    cd $WORKING_FOLDER
    mkdir /mnt/nanda
    mount /dev/nanda /mnt/nanda
    cp /mnt/nanda/script.bin script.bin
    bin2fex script.bin script.fex
    MAC_ADDRESS=$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\).*$/00\2\3\4\5\6/')
    sed -i "$ a\[dynamic]\nMAC = \"$MAC_ADDRESS\"" script.fex
    fex2bin script.fex script.bin
    cp script.bin /mnt/nanda/script.bin
    echo "Mac Address set to $MAC_ADDRESS" >> $SET_MAC_ADDR_LOG
    sync
    shutdown -r now
fi
TAGSETMACADDRESS

chmod +x /usr/local/bin/setmacaddr.sh

# add setting mac address to the rc.local
sed -i '/# By default this script does nothing./a /usr/local/bin/setmacaddr.sh' /etc/rc.local

# mount disk
cd /
mkdir data
sed -i '$ a\/dev/sda1 /data ext4 defaults 0 0' /etc/fstab
mount /dev/sda1 /data

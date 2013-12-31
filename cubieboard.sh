# update packages
apt-get update

WORKING_FOLDER=/tmp/syncloud

# packages for fex boot adjustment
apt-get install build-essential git
mkdir $WORKING_FOLDER
cd $WORKING_FOLDER
git clone https://github.com/linux-sunxi/sunxi-tools
cd sunxi-tools
make bin2fex
make fex2bin

# generate and fix mac address
mkdir /mnt/nanda
mount /dev/nanda /mnt/nanda
cp /mnt/nanda/script.bin $WORKING_FOLDER/script.bin
cd $WORKING_FOLDER
bin2fex script.bin script.fex
MAC_ADDRESS=$(echo dd if=/dev/urandom bs=1024 count=1 2>/dev/null|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\).*$/00\2\3\4\5\6/')
sed -i "$ a\[dynamic]\nMAC = \"$MAC_ADDRESS\"" script.fex
fex2bin script.fex script.bin
cp $WORKING_FOLDER/script.bin /mnt/nanda/script.bin
sync

# mount disk
cd /
mkdir data
sed -i '$ a\/dev/sda1 /data ext4 defaults 0 0' /etc/fstab
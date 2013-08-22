# update packages
apt-get update

# fix mac address
-> get mac address by ifconfig locate eth0 HWaddr
cd /boot
nano script.fex
--> add following text to the end
--> [dynamic]
--> MAC = "MAC ADDRESS"
fex2bin script.fex script.bin

# install disk
cd /
mkdir data
--> modify /etc/fstab - add /dev/sda1 to /data
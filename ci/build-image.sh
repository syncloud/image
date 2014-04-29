#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Building board: ${SYNCLOUD_BOARD}"

if [[ ${SYNCLOUD_BOARD} == "raspberrypi" ]]; then
  PARTITION=2
  USER=pi
  NAME=2014-01-07-wheezy-raspbian
  IMAGE_FILE=2014-01-07-wheezy-raspbian.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.zip
  DOWNLOAD_IMAGE="wget --progress=dot:mega http://downloads.raspberrypi.org/raspbian_latest -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
  BOARD=raspberrypi
elif [[ ${SYNCLOUD_BOARD} == "arm" ]]; then
  PARTITION=2
  USER=ubuntu
  IMAGE_FILE=BBB-eMMC-flasher-ubuntu-13.10-2014-02-16-2gb.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://rcn-ee.net/deb/flasher/saucy/$IMAGE_FILE_ZIP"
  UNZIP=unxz
  BOARD=beagleboneblack
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  PARTITION=1
  USER=cubie
  IMAGE_FILE=Cubian-base-r5-a20
  IMAGE_FILE_ZIP=$IMAGE_FILE.img.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega http://ubuntuone.com/108bqhMzhNOX5d4dNYO9x7 -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubieboard
fi
CI_TEMP=/data/syncloud/ci/temp
IMAGE_FILE_TEMP=$CI_TEMP/$IMAGE_FILE
echo "existing path: $PATH"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt-get -y update
apt-get -y install xz-utils git makeself p7zip

rm -rf owncloud-setup
git clone https://github.com/syncloud/owncloud-setup
cd owncloud-setup
SYNCLOUD_IMAGE=syncloud-$BOARD-$(date +%F-%H-%M-%S)-$(git rev-parse --short HEAD).img
./build.sh
cd ..

mkdir -p $CI_TEMP
if [ ! -f $IMAGE_FILE_TEMP ]; then
  echo "Base image $IMAGE_FILE_TEMP is not found, getting new one ..."
  $DOWNLOAD_IMAGE
  ls -la
  $UNZIP $IMAGE_FILE_ZIP
  mv $IMAGE_FILE $IMAGE_FILE_TEMP
fi

cp $IMAGE_FILE_TEMP $SYNCLOUD_IMAGE
FILE_INFO=$(file $SYNCLOUD_IMAGE)
echo $FILE_INFO

STARTSECTOR=$(echo $FILE_INFO | grep -oP 'partition ${PARTITION}.*startsector \K[0-9]*(?=, )')

if mount | grep image; then
  echo "image already mounted, unmounting ..."
  umount image
fi

lsof | grep image

if losetup -a | grep /dev/loop0; then
  echo "/dev/loop0 is already setup, deleting ..."
  losetup -d /dev/loop0
fi

losetup -o $(($STARTSECTOR*512)) /dev/loop0 $SYNCLOUD_IMAGE

if [ -d image ]; then 
  echo "image dir exists, deleting ..."
  rm -rf image
fi

mkdir image

mount /dev/loop0 image
if [ -f /run/resolvconf/resolv.conf ]; then
  mkdir -p image/run/resolvconf
  cp /run/resolvconf/resolv.conf image/run/resolvconf/resolv.conf
fi

cp owncloud-setup/syncloud_setup.sh image/home/$USER

chroot image rm -rf /var/cache/apt/archives/*.deb
chroot image rm -rf /opt/Wolfram

chroot image /home/$USER/syncloud_setup.sh

chroot image rm -rf /var/cache/apt/archives/*.deb
chroot image rm -rf /opt/Wolfram

if [ -f image/usr/sbin/minissdpd ]; then
  echo "stopping minissdpd holding the image ..."
  chroot image /etc/init.d/minissdpd stop
fi

umount image
rm -rf 
losetup -d /dev/loop0

xz -z0 $SYNCLOUD_IMAGE


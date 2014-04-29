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
  RESOLVCONF_FROM=
  RESOLVCONF_TO=
  RESIZE=
elif [[ ${SYNCLOUD_BOARD} == "arm" ]]; then
  PARTITION=2
  USER=ubuntu
  IMAGE_FILE=BBB-eMMC-flasher-ubuntu-13.10-2014-02-16-2gb.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://rcn-ee.net/deb/flasher/saucy/$IMAGE_FILE_ZIP"
  UNZIP=unxz
  BOARD=beagleboneblack
  RESOLVCONF_FROM=/run/resolvconf/resolv.conf
  RESOLVCONF_TO=/run/resolvconf/resolv.conf
  RESIZE=
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  PARTITION=1
  USER=cubie
  IMAGE_FILE=Cubian-base-r5-a20
  IMAGE_FILE_ZIP=$IMAGE_FILE.img.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega http://ubuntuone.com/108bqhMzhNOX5d4dNYO9x7 -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubieboard
  RESOLVCONF_FROM=/run/resolvconf/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  RESIZE=1500
fi
CI_TEMP=/data/syncloud/ci/temp
IMAGE_FILE_TEMP=$CI_TEMP/$IMAGE_FILE

function resize_image {
  
  local IMAGE=$1
  local SIZE=$2
  local PARTITION=$3
  local STARTSECTOR=$4
  
  echo "resizing $IMAGE, partition $PARTITION, start sector: $STARTSECTOR, end $SIZE MB"
 
  rm $IMAGE-new
  dd bs=1M count=$SIZE if=/dev/zero of=$IMAGE-new
  losetup /dev/loop0 $IMAGE
  losetup /dev/loop1 $IMAGE-new
  dd if=/dev/loop0 of=/dev/loop1
  losetup -d /dev/loop0
  parted /dev/loop1 <<- PARTED
	resizepart $PARTITION $SIZE
	quit
	PARTED
  losetup -d /dev/loop1
  rm $IMAGE
  mv $IMAGE-new $IMAGE
  losetup -o $STARTSECTOR /dev/loop0 $IMAGE
  e2fsck -f /dev/loop0
  resize2fs /dev/loop0
  losetup -d /dev/loop0
}

echo "existing path: $PATH"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt-get -y update
apt-get -y install xz-utils git makeself p7zip parted

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

STARTSECTOR=$(echo $FILE_INFO | grep -oP 'partition '$PARTITION'.*startsector \K[0-9]*(?=, )')
STARTSECTOR=$(($STARTSECTOR*512))
if mount | grep image; then
  echo "image already mounted, unmounting ..."
  umount image
fi

lsof | grep image

if losetup -a | grep /dev/loop0; then
  echo "/dev/loop0 is already setup, deleting ..."
  losetup -d /dev/loop0
fi

if [ -n $RESIZE ]; then
  resize_image $SYNCLOUD_IMAGE $RESIZE $PARTITION $STARTSECTOR 
fi 

losetup -o $STARTSECTOR /dev/loop0 $SYNCLOUD_IMAGE

if [ -d image ]; then 
  echo "image dir exists, deleting ..."
  rm -rf image
fi

mkdir image

mount /dev/loop0 image
if [ -n $RESOLVCONF_FROM ]; then
  mkdir -p image/$(dirname $RESOLVCONF_TO)
  cp $RESOLVCONF_FROM image$RESOLVCONF_TO
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

if [ -n $RESOLVCONF_FROM ]; then
  rm image$RESOLVCONF_TO
fi


umount image
rm -rf image
losetup -d /dev/loop0

xz -z0 $SYNCLOUD_IMAGE


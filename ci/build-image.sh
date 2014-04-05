#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ $(uname -n) == "raspberrypi" ]]; then
  USER=pi
  NAME=2014-01-07-wheezy-raspbian
  IMAGE_FILE=2014-01-07-wheezy-raspbian.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.zip
  IMAGE_URL="http://downloads.raspberrypi.org/raspbian_latest -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
elif [[ $(uname -n) == "arm" ]]; then
  USER=ubuntu
  IMAGE_FILE=BBB-eMMC-flasher-ubuntu-13.10-2014-02-16-2gb.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  IMAGE_URL=https://rcn-ee.net/deb/flasher/saucy/$IMAGE_FILE_ZIP
  UNZIP=unxz
fi

GIT_URL=https://github.com/syncloud/owncloud-setup
REV_FILE=.revision
cd /data
mkdir -p syncloud
cd syncloud


LATEST_REV=$(git ls-remote $GIT_URL refs/heads/master | cut -f1)
if [ -f $REV_FILE ]; then
  CURRENT_REV=$(<$REV_FILE)
  if [ "$CURRENT_REV" == "$LATEST_REV" ]; then
    echo "No changes since last check"
    exit 1
  fi
fi

echo $LATEST_REV > $REV_FILE

apt-get install xz-utils git makeself

rm -rf owncloud-setup
git clone https://github.com/syncloud/owncloud-setup
cd owncloud-setup
./build.sh
cd ..

if [ ! -f $IMAGE_FILE ]; then
  wget $IMAGE_URL
  $UNZIP $IMAGE_FILE_ZIP
  rm $IMAGE_FILE_ZIP
fi

#fdisk $IMAGE_FILE
STARTSECTOR=$(file $IMAGE_FILE | grep -oP 'partition 2.*startsector \K[0-9]*(?=, )')
losetup -o $(($STARTSECTOR*512)) /dev/loop0 $IMAGE_FILE
mkdir image
mount /dev/loop0 image
cp owncloud-setup/syncloud_setup.sh image/home/$USER
chroot image
cd /home/$USER

exit
umount /dev/loop0
rm -rf image
losetupd -d /dev/loop0

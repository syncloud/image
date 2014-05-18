#!/bin/bash -x

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SYNCLOUD_BOARD=$(uname -n)

CI_TEMP=/data/syncloud/ci/temp

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
  KILL_HOST_MYSQL=false
  STOP_NTP=false
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
  KILL_HOST_MYSQL=false
  STOP_NTP=false
elif [[ ${SYNCLOUD_BOARD} == "Cubian" ]]; then
  PARTITION=1
  USER=cubie
  IMAGE_FILE=Cubian-base-r5-a20-ct-large.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://www.dropbox.com/s/m5hfp7escijllaj/Cubian-base-r5-a20-ct-large.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubietruck
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  RESIZE=
  KILL_HOST_MYSQL=true
  STOP_NTP=true
fi
IMAGE_FILE_TEMP=$CI_TEMP/$IMAGE_FILE

echo "existing path: $PATH"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SYNCLOUD_IMAGE=syncloud-$BOARD-$(date +%F-%H-%M-%S)-$(git rev-parse --short HEAD).img

# build syncloud setup script
./build.sh

# checking if base image file already present, download and resize if doesn't 
mkdir -p $CI_TEMP
if [ ! -f $IMAGE_FILE_TEMP ]; then
  echo "Base image $IMAGE_FILE_TEMP is not found, getting new one ..."
  $DOWNLOAD_IMAGE
  ls -la
  $UNZIP $IMAGE_FILE_ZIP

  if [ -n "$RESIZE" ]; then
    echo "Need to resize base image, resizing ..."
    ./resize-partition.sh $IMAGE_FILE $PARTITION $RESIZE
  fi

  mv $IMAGE_FILE $IMAGE_FILE_TEMP
fi

# copy image file we are going to modify
cp $IMAGE_FILE_TEMP $SYNCLOUD_IMAGE

# command for getting image partitions information
FILE_INFO=$(file $SYNCLOUD_IMAGE)
echo $FILE_INFO

# retrieving partition start sector
STARTSECTOR=$(echo $FILE_INFO | grep -oP 'partition '$PARTITION'.*startsector \K[0-9]*(?=, )')
STARTSECTOR=$(($STARTSECTOR*512))
if mount | grep image; then
  echo "image already mounted, unmounting ..."
  umount image
fi

# checking who is using image folder
lsof | grep image

# if /dev/loop0 is mapped then unmap it
if losetup -a | grep /dev/loop0; then
  echo "/dev/loop0 is already setup, deleting ..."
  losetup -d /dev/loop0
fi

# map /dev/loop0 to image file
losetup -o $STARTSECTOR /dev/loop0 $SYNCLOUD_IMAGE

if [ -d image ]; then 
  echo "image dir exists, deleting ..."
  rm -rf image
fi

# mount /dev/loop0 to image folder
rm -rf image
mkdir image

mount /dev/loop0 image
if [ -n "$RESOLVCONF_FROM" ]; then
  mkdir -p image/$(dirname $RESOLVCONF_TO)
  cp $RESOLVCONF_FROM image$RESOLVCONF_TO
fi

# copy syncloud setup script to image
cp syncloud_setup.sh image/home/$USER

chroot image rm -rf /var/cache/apt/archives/*.deb
chroot image rm -rf /opt/Wolfram

chroot image /home/$USER/syncloud_setup.sh

chroot image rm -rf /var/cache/apt/archives/*.deb
chroot image rm -rf /opt/Wolfram

if [ -f image/usr/sbin/minissdpd ]; then
  echo "stopping minissdpd holding the image ..."
  chroot image /etc/init.d/minissdpd stop
fi

if [ "$STOP_NTP" = true ] ; then
    echo 'Stopping ntp'
    chroot image service ntp stop
fi

if [ "$KILL_HOST_MYSQL" = true ] ; then
    echo 'Killing host mysql!'
    chroot image service mysql stop
    pkill mysqld
fi

if [ -n "$RESOLVCONF_FROM" ]; then
  rm image$RESOLVCONF_TO
fi

while [ "$(lsof | grep image | grep -v "build-image.sh")" ]
do
  sleep 5
  echo "waiting for all proccesses using image to die"
done

umount image
losetup -d /dev/loop0

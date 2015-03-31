#!/bin/bash -x

who mom likes

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "existing path: $PATH"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

wget -qO- https://raw.githubusercontent.com/syncloud/apps/$(<RELEASE)/bootstrap.sh | bash

SYNCLOUD_BOARD=$(syncloud-id name --text)
PLATFORM=$(uname -i)

CI_TEMP=/data/syncloud/ci/temp

echo "Building board: ${SYNCLOUD_BOARD}"

if [[ ${SYNCLOUD_BOARD} == "raspberrypi" ]]; then
  USER=pi
  IMAGE_FILE=2015-02-16-raspbian-wheezy.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.zip
  DOWNLOAD_IMAGE="wget --progress=dot:mega http://downloads.raspberrypi.org/raspbian_latest -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
  BOARD=raspberrypi
  RESOLVCONF_FROM=
  RESOLVCONF_TO=
  NEW_SIZE_MB=
  KILL_SERVICES=false
  INIT_RANDOM=false
  RESIZE_PARTITION_ON_FIRST_BOOT=false
elif [[ ${SYNCLOUD_BOARD} == "beagleboneblack" ]]; then
  USER=debian
  IMAGE_FILE=bone-debian-7.8-console-armhf-2015-02-19-2gb.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://rcn-ee.net/rootfs/2015-02-19/microsd/$IMAGE_FILE_ZIP"
  UNZIP=unxz
  BOARD=beagleboneblack
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  NEW_SIZE_MB=
  KILL_SERVICES=false
  INIT_RANDOM=false
  RESIZE_PARTITION_ON_FIRST_BOOT=false
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  USER=cubie
  IMAGE_FILE="Cubian-nano+headless-x1-a10.img"
  IMAGE_FILE_ZIP=$IMAGE_FILE.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://s3-us-west-2.amazonaws.com/syncloud-distributives/Cubian-nano%2Bheadless-x1-a10.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubieboard
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  NEW_SIZE_MB=2000
  KILL_SERVICES=false
  INIT_RANDOM=true
  RESIZE_PARTITION_ON_FIRST_BOOT=true
elif [[ ${SYNCLOUD_BOARD} == "cubieboard2" ]]; then
  USER=cubie
  IMAGE_FILE="Cubian-nano+headless-x1-a20.img"
  IMAGE_FILE_ZIP=$IMAGE_FILE.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://s3-us-west-2.amazonaws.com/syncloud-distributives/Cubian-nano%2Bheadless-x1-a20.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubieboard2
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  NEW_SIZE_MB=2000
  KILL_SERVICES=false
  INIT_RANDOM=true
  RESIZE_PARTITION_ON_FIRST_BOOT=true
elif [[ ${SYNCLOUD_BOARD} == "cubietruck" ]]; then
  USER=cubie
  IMAGE_FILE="Cubian-nano+headless-x1-a20-cubietruck.img"
  IMAGE_FILE_ZIP=$IMAGE_FILE.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://s3-us-west-2.amazonaws.com/syncloud-distributives/Cubian-nano%2Bheadless-x1-a20-cubietruck.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubietruck
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  NEW_SIZE_MB=2000
  KILL_SERVICES=false
  INIT_RANDOM=true
  RESIZE_PARTITION_ON_FIRST_BOOT=true
elif [[ ${SYNCLOUD_BOARD} == "odroid-xu3" ]]; then
  USER=debian
  IMAGE_FILE=odroid-xu3-debian-wheezy-7.5-armhf-init-20150314.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://s3-us-west-2.amazonaws.com/syncloud/odroid-xu3-debian-wheezy-7.5-armhf-init-20150314.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
  BOARD=odroid-xu3
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  NEW_SIZE_MB=
  KILL_SERVICES=false
  INIT_RANDOM=false
  RESIZE_PARTITION_ON_FIRST_BOOT=false

elif [[ ${PLATFORM} == "x86_64" ]]; then
  USER=syncloud
  IMAGE_FILE=syncloud-x86-v0.2.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://github.com/syncloud/image-x86/releases/download/v0.3/ubuntu-amd64-v0.3.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
  BOARD=x86
  RESOLVCONF_FROM=/run/resolvconf/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  NEW_SIZE_MB=
  KILL_SERVICES=false
  INIT_RANDOM=false
  RESIZE_PARTITION_ON_FIRST_BOOT=false
fi
IMAGE_FILE_TEMP=$CI_TEMP/$IMAGE_FILE

apt-get update
apt-get install -y wget parted xz-utils lsof libpcre3

if [[ -z "$1" ]]; then
  BUILD_ID=$(date +%F-%H-%M-%S)
else
  BUILD_ID=$1
fi

SYNCLOUD_IMAGE=syncloud-$BOARD-$BUILD_ID.img

# checking if base image file already present, download and resize if doesn't
mkdir -p $CI_TEMP
if [ ! -f $IMAGE_FILE_TEMP ]; then
  echo "Base image $IMAGE_FILE_TEMP is not found, getting new one ..."
  $DOWNLOAD_IMAGE
  ls -la
  $UNZIP $IMAGE_FILE_ZIP

  if [ -n "$NEW_SIZE_MB" ]; then
    echo "Need to resize base image, resizing ..."
    ./resize-partition.sh $IMAGE_FILE $NEW_SIZE_MB
  fi

  mv $IMAGE_FILE $IMAGE_FILE_TEMP
fi

# copy image file we are going to modify
cp $IMAGE_FILE_TEMP $SYNCLOUD_IMAGE

# folder for mounting image file
IMAGE_FOLDER=imgmnt

if mount | grep $IMAGE_FOLDER; then
  echo "image already mounted, unmounting ..."
  umount $IMAGE_FOLDER
fi

# checking who is using image folder
lsof | grep $IMAGE_FOLDER

LOOP_DEVICE=/dev/loop0;

# if /dev/loop0 is mapped then unmap it
if losetup -a | grep $LOOP_DEVICE; then
  echo "/dev/loop0 is already setup, deleting ..."
  losetup -d $LOOP_DEVICE
fi

# number of lines in parted print
PARTED_LINES=$(parted -sm $SYNCLOUD_IMAGE unit B print | wc -l)

# first two lines in parted print are not about partitions
PARTITION=$(expr $PARTED_LINES - 2)

# get partition start in bytes
PART_START_BYTES=$(parted -sm $SYNCLOUD_IMAGE unit B print | grep -oP "^${PARTITION}:\K[0-9]*(?=B)")

# map /dev/loop0 to image file
losetup -o $PART_START_BYTES $LOOP_DEVICE $SYNCLOUD_IMAGE

if [ -d $IMAGE_FOLDER ]; then 
  echo "$IMAGE_FOLDER dir exists, deleting ..."
  rm -rf $IMAGE_FOLDER
fi

# mount /dev/loop0 to IMAGE_FOLDER folder
pwd
mkdir $IMAGE_FOLDER

mount $LOOP_DEVICE $IMAGE_FOLDER

mount -t proc proc $IMAGE_FOLDER/proc

if [ -n "$RESOLVCONF_FROM" ]; then
  RESOLV_DIR=$IMAGE_FOLDER/$(dirname $RESOLVCONF_TO)
  echo "creatig resolv conf dir: ${RESOLV_DIR}"
  mkdir -p $RESOLV_DIR
  rm -rf $IMAGE_FOLDER$RESOLVCONF_TO
  echo "copying resolv conf from $RESOLVCONF_FROM to $IMAGE_FOLDER$RESOLVCONF_TO"
  cp $RESOLVCONF_FROM $IMAGE_FOLDER$RESOLVCONF_TO
fi

if [ "$INIT_RANDOM" = true ] ; then
  chroot ${IMAGE_FOLDER} mknod /dev/random c 1 8
  chroot ${IMAGE_FOLDER} mknod /dev/urandom c 1 9
fi

#Image build version
mkdir -p ${IMAGE_FOLDER}/etc/syncloud
git rev-parse --short HEAD > ${IMAGE_FOLDER}/etc/syncloud/version

if [ -f /etc/syncloud/version ]; then
  cat /etc/syncloud/version > ${IMAGE_FOLDER}/etc/syncloud/builder
else
  echo "Non syncloud image (probably base image)" > ${IMAGE_FOLDER}/etc/syncloud/builder
fi

# copy syncloud setup script to IMAGE_FOLDER
cp disable-service-restart.sh $IMAGE_FOLDER/tmp
chroot $IMAGE_FOLDER /tmp/disable-service-restart.sh

cp RELEASE $IMAGE_FOLDER/tmp
cp syncloud.sh $IMAGE_FOLDER/tmp
chroot $IMAGE_FOLDER /tmp/syncloud.sh

cp enable-service-restart.sh $IMAGE_FOLDER/tmp
chroot $IMAGE_FOLDER /tmp/enable-service-restart.sh

umount $IMAGE_FOLDER/proc

if [ -f $IMAGE_FOLDER/usr/sbin/minissdpd ]; then
  echo "stopping minissdpd holding the $IMAGE_FOLDER ..."
  chroot $IMAGE_FOLDER /etc/init.d/minissdpd stop
fi

if [ "$RESIZE_PARTITION_ON_FIRST_BOOT" = true ] ; then
    touch $IMAGE_FOLDER/var/lib/resize_partition_flag
fi

if [ "$KILL_SERVICES" = true ] ; then

    echo 'Stopping ntp'
    chroot $IMAGE_FOLDER service ntp stop

    echo 'Killing mysql!'
    chroot $IMAGE_FOLDER service mysql stop
    pkill mysqld
    
    echo 'Killing apache!'
    chroot $IMAGE_FOLDER service apache2 stop
    pkill apache2
fi


if [ -n "$RESOLVCONF_FROM" ]; then
  echo "removing resolv conf: $IMAGE_FOLDER$RESOLVCONF_TO"
  rm $IMAGE_FOLDER$RESOLVCONF_TO
fi

while lsof | grep $IMAGE_FOLDER | grep -v "build-image.sh" > /dev/null
do 
  sleep 5
  echo "waiting for all proccesses using $IMAGE_FOLDER to die"
done

echo "unmounting $IMAGE_FOLDER"
umount $IMAGE_FOLDER

echo "removing loop device"
losetup -d $LOOP_DEVICE

echo "build finished"

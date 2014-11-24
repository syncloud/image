#!/bin/bash -x

who mom likes

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ls -la /usr/local/bin/pip*

wget -qO- https://raw.githubusercontent.com/syncloud/apps/$(<RELEASE)/bootstrap.sh | bash

ls -la /usr/local/bin/pip*

sam install syncloud-id

SYNCLOUD_BOARD=$(syncloud-id name --text)
PLATFORM=$(uname -i)

CI_TEMP=/data/syncloud/ci/temp

echo "Building board: ${SYNCLOUD_BOARD}"

if [[ ${SYNCLOUD_BOARD} == "raspberrypi" ]]; then
  PARTITION=2
  USER=pi
  IMAGE_FILE=2014-09-09-wheezy-raspbian.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.zip
  DOWNLOAD_IMAGE="wget --progress=dot:mega http://downloads.raspberrypi.org/raspbian_latest -O $IMAGE_FILE_ZIP"
  UNZIP=unzip
  BOARD=raspberrypi
  RESOLVCONF_FROM=
  RESOLVCONF_TO=
  RESIZE=
  KILL_SERVICES=false
  INIT_RANDOM=false
elif [[ ${SYNCLOUD_BOARD} == "beagleboneblack" ]]; then
  PARTITION=2
  USER=debian
  IMAGE_FILE=bone-debian-7.7-console-armhf-2014-10-29-2gb.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://rcn-ee.net/deb/microsd/wheezy/$IMAGE_FILE_ZIP"
  UNZIP=unxz
  BOARD=beagleboneblack
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  RESIZE=
  KILL_SERVICES=false
  INIT_RANDOM=false
elif [[ ${SYNCLOUD_BOARD} == "cubieboard" ]]; then
  PARTITION=1
  USER=cubie
  IMAGE_FILE=Cubian-base-r8-a10-large.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://www.dropbox.com/s/spnhzwhsit9ggz6/Cubian-base-r8-a10-large.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubieboard
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  RESIZE=
  KILL_SERVICES=true
  INIT_RANDOM=true
elif [[ ${SYNCLOUD_BOARD} == "cubieboard2" ]]; then
  PARTITION=1
  USER=cubie
  IMAGE_FILE=Cubian-base-r5-a20-large.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.7z
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://www.dropbox.com/s/vh8nsrsloplwji0/Cubian-base-r5-a20-large.img.7z -O $IMAGE_FILE_ZIP"
  UNZIP="p7zip -d"
  BOARD=cubieboard2
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  RESIZE=
  KILL_SERVICES=true
  INIT_RANDOM=true
elif [[ ${SYNCLOUD_BOARD} == "cubietruck" ]]; then
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
  KILL_SERVICES=true
  INIT_RANDOM=true
elif [[ ${PLATFORM} == "x86_64" ]]; then
  STARTSECTOR=0
  USER=syncloud
  IMAGE_FILE=syncloud-x86-v0.2.img
  IMAGE_FILE_ZIP=$IMAGE_FILE.xz
  DOWNLOAD_IMAGE="wget --progress=dot:mega https://github.com/syncloud/image-x86/releases/download/v0.3/ubuntu-amd64-v0.3.img.xz -O $IMAGE_FILE_ZIP"
  UNZIP=unxz
  BOARD=x86
  RESOLVCONF_FROM=/etc/resolv.conf
  RESOLVCONF_TO=/etc/resolv.conf
  RESIZE=
  KILL_SERVICES=false
  INIT_RANDOM=false
fi
IMAGE_FILE_TEMP=$CI_TEMP/$IMAGE_FILE

echo "existing path: $PATH"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt-get update
apt-get install -y wget parted xz-utils lsof

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

  if [ -n "$RESIZE" ]; then
    echo "Need to resize base image, resizing ..."
    ./resize-partition.sh $IMAGE_FILE $PARTITION $RESIZE
  fi

  mv $IMAGE_FILE $IMAGE_FILE_TEMP
fi

# copy image file we are going to modify
cp $IMAGE_FILE_TEMP $SYNCLOUD_IMAGE

if [ -z "$STARTSECTOR" ]; then
    # retrieving partition start sector
    STARTSECTOR=$(parted -sm $SYNCLOUD_IMAGE unit B print | grep -oP "^${PARTITION}:\K[0-9]*(?=B)")
fi

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

# map /dev/loop0 to image file
losetup -o $STARTSECTOR $LOOP_DEVICE $SYNCLOUD_IMAGE

if [ -d $IMAGE_FOLDER ]; then 
  echo "$IMAGE_FOLDER dir exists, deleting ..."
  rm -rf $IMAGE_FOLDER
fi

# mount /dev/loop0 to IMAGE_FOLDER folder
pwd
mkdir $IMAGE_FOLDER

mount $LOOP_DEVICE $IMAGE_FOLDER

if [ -n "$RESOLVCONF_FROM" ]; then
  RESOLV_DIR=$IMAGE_FOLDER/$(dirname $RESOLVCONF_TO)
  echo "creatig resolv conf dir: ${RESOLV_DIR}"
  mkdir -p $RESOLV_DIR
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

if [ -f $IMAGE_FOLDER/usr/sbin/minissdpd ]; then
  echo "stopping minissdpd holding the $IMAGE_FOLDER ..."
  chroot $IMAGE_FOLDER /etc/init.d/minissdpd stop
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

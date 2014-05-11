#!/bin/bash -x

SYNCLOUD_IMAGE=$1
PARTITION=$2
SIZE=$3

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
  e2fsck -pf /dev/loop0
  resize2fs /dev/loop0
  losetup -d /dev/loop0
}

FILE_INFO=$(file $SYNCLOUD_IMAGE)
echo $FILE_INFO

STARTSECTOR=$(echo $FILE_INFO | grep -oP 'partition '$PARTITION'.*startsector \K[0-9]*(?=, )')
STARTSECTOR=$(($STARTSECTOR*512))

echo $PARTITION


if mount | grep image; then
  echo "image already mounted, unmounting ..."
  umount image
fi

lsof | grep image

if losetup -a | grep /dev/loop0; then
  echo "/dev/loop0 is already setup, deleting ..."
  losetup -d /dev/loop0
fi

resize_image $SYNCLOUD_IMAGE $SIZE $PARTITION $STARTSECTOR

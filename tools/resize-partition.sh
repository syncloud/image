#!/bin/bash

IMAGE_FILE=$1

# these megabytes are equal 1024 x 1024 bytes, all math with megabytes below is the same
SIZE_MB=$2

function resize_partition {

  local IMAGE_FILE=$1
  local PARTITION=$2
  local PART_START_BYTES=$3
  local PART_END_BYTES=$4

  echo "resizing $IMAGE_FILE, partition: $PARTITION, start byte: $PART_START_BYTES, end byte: $PART_END_BYTES"

  # size is +1 to number of last byte
  local NEW_IMAGE_SIZE_BYTES=$(expr $PART_END_BYTES + 1)

  # add one Mb at the end for cases when size is not even
  local NEW_IMAGE_SIZE_MB=$(expr $NEW_IMAGE_SIZE_BYTES / 1024 / 1024 + 1)

  # create file of bigger size filled with zeros
  rm -rf $IMAGE_FILE-new
  dd bs=1M count=$NEW_IMAGE_SIZE_MB if=/dev/zero of=$IMAGE_FILE-new

  losetup /dev/loop0 $IMAGE_FILE

  # print partitions - current state
  parted -s /dev/loop0 print

  # copy original image to a new bigger file
  losetup /dev/loop1 $IMAGE_FILE-new
  dd if=/dev/loop0 of=/dev/loop1
  sync
  losetup -d /dev/loop0

  # remove partition
  parted -sm /dev/loop1 rm $PARTITION

  # create partition of new size
  parted -sm /dev/loop1 unit B mkpart primary $PART_START_BYTES $PART_END_BYTES

  # print partitions - after resizing
  parted -s /dev/loop1 print
  mount
  losetup -a
  sync
  losetup -d /dev/loop1

  # new partition size in 4K blocks
  SIZE_BLOCKS=$(expr $SIZE_MB \* 1024 / 4)

  # check filesystem and expand it
  losetup -o $PART_START_BYTES /dev/loop1 $IMAGE_FILE-new
  e2fsck -pf /dev/loop1
  resize2fs /dev/loop1 $SIZE_BLOCKS
  sync
  losetup -d /dev/loop1

  # replace image file with new one
  rm -rf $IMAGE_FILE
  mv $IMAGE_FILE-new $IMAGE_FILE
}

# number of lines in parted print
PARTED_LINES=$(parted -sm $IMAGE_FILE unit B print | wc -l)

# first two lines in parted print are not about partitions
PARTITION=$(expr $PARTED_LINES - 2)

# get partition start in bytes
PART_START_BYTES=$(parted -sm $IMAGE_FILE unit B print | grep -oP "^${PARTITION}:\K[0-9]*(?=B)")

# calculate new image size in bytes
TOTAL_SIZE_BYTES=$(expr $PART_START_BYTES + $SIZE_MB \* 1024 \* 1024)

# calculate partition end in bytes - just get the number of last byte
PART_END_BYTES=$(expr $TOTAL_SIZE_BYTES - 1)


# some cleanup of mount and losetup
if mount | grep image; then
  echo "image already mounted, unmounting ..."
  umount image
fi

lsof | grep image

if losetup -a | grep /dev/loop0; then
  echo "/dev/loop0 is already setup, deleting ..."
  sync
  losetup -d /dev/loop0
fi

# run resize function
resize_partition $IMAGE_FILE $PARTITION $PART_START_BYTES $PART_END_BYTES

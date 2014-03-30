#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ADDRESS=localhost
PORT=5022
SSH_USER=pi
SSH_PASS=raspberry
BASE_IMAGE=2014-01-07-wheezy-raspbian.img
SYNCLOUD_IMAGE=syncloud-raspberrypi.img
SCRIPT_NAME=syncloud_setup.sh

#raspberry
#From the output of the file command, take the partition 2 'startsector' value an multiply by 512, and use this figure as the offset value in the mount command below.
OFFSET=62914560

VM_UP=0
VM_DOWN=1


function wait_for {

  if [ $1 -eq $VM_UP ]; then
    RETVAL=1
  else
    RETVAL=0
  fi

  while [[ ( $RETVAL -ne 0 ) && ( $1 -eq $VM_UP ) || ( $RETVAL -eq 0 ) && ( $1 -eq $VM_DOWN ) ]]
  do

    sshpass -p "$SSH_PASS" ssh -oStrictHostKeyChecking=no -p $PORT $SSH_USER@$ADDRESS uptime

    RETVAL=$?
    [ $RETVAL -eq 0 ] && echo Up $RETVAL
    [ $RETVAL -ne 0 ] && echo Down $RETVAL

    sleep 1

  done
}

function mount_image {
  mkdir mnt
  losetup -o $OFFSET /dev/loop0 $SYNCLOUD_IMAGE
  mount  /dev/loop0 ./mnt
}

function umount_image {
  umount ./mnt
  rm -rf ./mnt
  fsck /dev/loop0
  losetup -d /dev/loop0
}

./build.sh

rm $SYNCLOUD_IMAGE
rsync --progress $BASE_IMAGE $SYNCLOUD_IMAGE

ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:5022

#Fixing raspberry image for qemu boot
if [[ $BASE_IMAGE == *raspbian* ]]; then
  mount_image
  sed -i -e 's/^\/usr/#\/usr/g' ./mnt/etc/ld.so.preload
  umount_image
fi

qemu-system-arm -kernel kernel-qemu -cpu arm1176 -m 256 -M versatilepb -no-reboot -serial stdio -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" -hda $SYNCLOUD_IMAGE -redir tcp:$PORT::22 & 
pid=$!    

wait_for $VM_UP

sshpass -p "$SSH_PASS" scp -P $PORT ./$SCRIPT_NAME $SSH_USER@$ADDRESS:/home/$SSH_USER/$SCRIPT_NAME
sshpass -p "$SSH_PASS" ssh -oStrictHostKeyChecking=no -p $PORT $SSH_USER@$ADDRESS << TAGRUNSSH
echo $SSH_PASS | sudo -S /home/$SSH_USER/$SCRIPT_NAME
rm /home/$SSH_USER/$SCRIPT_NAME
shutdown -r 0
TAGRUNSSH

kill -9 $pid

#Unfixing raspberry image from qemu boot
if [[ $BASE_IMAGE == *raspbian* ]]; then
  mount_image                            
  sed -i -e 's/^#\/usr/\/usr/g' ./mnt/etc/ld.so.preload
  umount_image
fi

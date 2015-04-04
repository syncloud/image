#!/bin/bash

ADDRESS=$1
PORT=$2
SSH_USER=$3
SSH_PASS=$4

CUBIE_IMAGE_NAME=$5

########################################################
# Getting images of NAND partitions

# Do disk dump through ssh
sshpass -p "$SSH_PASS" ssh -oStrictHostKeyChecking=no -t -p $PORT $SSH_USER@$ADDRESS << TAGRUNSSH
echo -e "$SSH_PASS" | sudo -S rm -rf /data/rootfs.fex.iso /data/libs.fex.iso
echo -e "$SSH_PASS" | sudo -S dd if=/dev/nandc of=/data/rootfs.fex.iso
echo -e "$SSH_PASS" | sudo -S sync
echo -e "$SSH_PASS" | sudo -S dd if=/dev/nandd of=/data/libs.fex.iso
echo -e "$SSH_PASS" | sudo -S sync
TAGRUNSSH

# Copy files to this machine throug scp
sshpass -p "$SSH_PASS" scp -P $PORT $SSH_USER@$ADDRESS:/data/rootfs.fex.iso rootfs.fex.iso
sshpass -p "$SSH_PASS" scp -P $PORT $SSH_USER@$ADDRESS:/data/libs.fex.iso libs.fex.iso


########################################################
# Packing images of NAND partitions into AllWinner image

# Delete previously created image
rm -rf syncloud.$CUBIE_IMAGE_NAME

# Unpack vendor image
imgrepacker $CUBIE_IMAGE_NAME
mv $CUBIE_IMAGE_NAME.dump syncloud.$CUBIE_IMAGE_NAME.dump

# Overwrite images of nandc and nandd partitions
mv -f rootfs.fex.iso syncloud.$CUBIE_IMAGE_NAME.dump/_iso/
mv -f libs.fex.iso syncloud.$CUBIE_IMAGE_NAME.dump/_iso/

# Pack dump back into AllWinner NAND image
imgrepacker syncloud.$CUBIE_IMAGE_NAME.dump
sync

# Delete dump folder
rm -rf syncloud.$CUBIE_IMAGE_NAME.dump

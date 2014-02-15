#!/bin/bash

CUBIE_ADDRESS=$1
CUBIE_PORT=$2
CUBIE_SSH_USER=$3
CUBIE_SSH_PASS=$4

sshpass -p "$CUBIE_SSH_PASS" ssh -oStrictHostKeyChecking=no -t -p $CUBIE_PORT $CUBIE_SSH_USER@$CUBIE_ADDRESS << TAGRUNSSH
rm -rf /home/$CUBIE_SSH_USER/rootfs.fex.iso /home/$CUBIE_SSH_USER/libs.fex.iso
echo -e "$CUBIE_SSH_PASS" | sudo -S dd if=/dev/nandc of=/home/$CUBIE_SSH_USER/rootfs.fex.iso
echo -e "$CUBIE_SSH_PASS" | sudo -S sync
echo -e "$CUBIE_SSH_PASS" | sudo -S dd if=/dev/nandd of=/home/$CUBIE_SSH_USER/libs.fex.iso
echo -e "$CUBIE_SSH_PASS" | sudo -S sync
TAGRUNSSH

rm -rf rootfs.fex.iso libs.fex.iso

sshpass -p "$CUBIE_SSH_PASS" scp -P $CUBIE_PORT $CUBIE_SSH_USER@$CUBIE_ADDRESS:~/rootfs.fex.iso rootfs.fex.iso
sshpass -p "$CUBIE_SSH_PASS" scp -P $CUBIE_PORT $CUBIE_SSH_USER@$CUBIE_ADDRESS:~/libs.fex.iso libs.fex.iso

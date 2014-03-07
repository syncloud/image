#!/bin/bash

ADDRESS=$1
PORT=$2
SSH_USER=$3
SSH_PASS=$4

sshpass -p "$SSH_PASS" scp -P $PORT ./owncloud.sh $SSH_USER@$ADDRESS:/home/$SSH_USER/owncloud.sh

sshpass -p "$SSH_PASS" ssh -oStrictHostKeyChecking=no -p $PORT $SSH_USER@$ADDRESS << TAGRUNSSH
echo $SSH_PASS | sudo -S /home/$SSH_USER/owncloud.sh
rm /home/$SSH_USER/owncloud.sh
TAGRUNSSH

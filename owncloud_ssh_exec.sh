#!/bin/bash

ADDRESS=$1
PORT=$2
SSH_USER=$3
SSH_PASS=$4

SCRIPT_NAME=owncloud_setup.sh

sshpass -p "$SSH_PASS" scp -P $PORT ./$SCRIPT_NAME $SSH_USER@$ADDRESS:/home/$SSH_USER/$SCRIPT_NAME

sshpass -p "$SSH_PASS" ssh -oStrictHostKeyChecking=no -p $PORT $SSH_USER@$ADDRESS << TAGRUNSSH
echo $SSH_PASS | sudo -S /home/$SSH_USER/$SCRIPT_NAME
rm /home/$SSH_USER/$SCRIPT_NAME
TAGRUNSSH

#!/bin/bash

CUBIE_ADDRESS=$1
CUBIE_PORT=$2
CUBIE_SSH_USER=$3
CUBIE_SSH_PASS=$4

sshpass -p "$CUBIE_SSH_PASS" scp -P $CUBIE_PORT ./cubieboard.sh $CUBIE_SSH_USER@$CUBIE_ADDRESS:/home/$CUBIE_SSH_USER/cubieboard.sh
sshpass -p "$CUBIE_SSH_PASS" scp -P $CUBIE_PORT ./owncloud.sh $CUBIE_SSH_USER@$CUBIE_ADDRESS:/home/$CUBIE_SSH_USER/owncloud.sh

sshpass -p "$CUBIE_SSH_PASS" ssh -oStrictHostKeyChecking=no -p $CUBIE_PORT $CUBIE_SSH_USER@$CUBIE_ADDRESS << TAGRUNSSH
echo $CUBIE_SSH_PASS | sudo -S /home/$CUBIE_SSH_USER/cubieboard.sh
echo $CUBIE_SSH_PASS | sudo -S /home/$CUBIE_SSH_USER/owncloud.sh
rm /home/$CUBIE_SSH_USER/cubieboard.sh /home/$CUBIE_SSH_USER/owncloud.sh
TAGRUNSSH
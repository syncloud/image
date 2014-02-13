#!/bin/bash

CUBIE_ADDRESS=$1
CUBIE_PORT=$2
CUBIE_SSH_USER=$3
CUBIE_SSH_PASS=$4

sshpass -p "$CUBIE_SSH_PASS" scp -P $CUBIE_PORT $CUBIE_SSH_USER@$CUBIE_ADDRESS:/data/rootfs.fex.iso ./rootfs.fex.iso
sshpass -p "$CUBIE_SSH_PASS" scp -P $CUBIE_PORT $CUBIE_SSH_USER@$CUBIE_ADDRESS:/data/libs.fex.iso ./libs.fex.iso
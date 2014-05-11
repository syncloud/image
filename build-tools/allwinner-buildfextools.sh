#!/bin/bash

# packages for fex boot adjustment
WORKING_FOLDER=/tmp/syncloud
apt-get install build-essential git
mkdir $WORKING_FOLDER
cd $WORKING_FOLDER
git clone https://github.com/linux-sunxi/sunxi-tools
cd sunxi-tools
make bin2fex
make fex2bin

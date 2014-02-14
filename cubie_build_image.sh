#!/bin/bash

CUBIE_IMAGE_NAME=$1

imgrepacker $CUBIE_IMAGE_NAME

mv $CUBIE_IMAGE_NAME.dump syncloud.$CUBIE_IMAGE_NAME.dump

mv -f rootfs.fex.iso syncloud.$CUBIE_IMAGE_NAME.dump/_iso/
mv -f libs.fex.iso syncloud.$CUBIE_IMAGE_NAME.dump/_iso/

imgrepacker syncloud.$CUBIE_IMAGE_NAME.dump
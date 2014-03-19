#!/bin/bash

DATADIR=$1

chmod 770 $DATADIR
chown -R www-data:www-data $DATADIR

#!/bin/bash -x

syncloud-apache activate localhost
owncloud-ctl finish test test http
ls -la /data
owncloud-ctl verify
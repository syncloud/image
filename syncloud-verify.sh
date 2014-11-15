#!/bin/bash -x

owncloud-ctl finish test test http
ls -la /data
owncloud-ctl verify
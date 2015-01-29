#!/bin/bash -x

syncloud-apache --debug activate localhost
owncloud-ctl --debug finish test test http
ls -la /data
owncloud-ctl --debug verify
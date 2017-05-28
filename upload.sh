#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

release=$1
file=$2
bucket=image.syncloud.org

if [ ! -f /usr/bin/s3cmd ]; then
    ${DIR}/install-s3cmd.sh
fi

if [ "${branch}" == "master" ] || [ "${branch}" == "stable" ] ; then
  
  s3cmd put ${file} s3://${bucket}/$release/$file

fi


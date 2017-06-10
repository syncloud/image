#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

release=$1
file=$2
branch=$3
bucket=image.syncloud.org

if [ "${branch}" == "master" ] || [ "${branch}" == "stable" ] ; then
  
  s3cmd put ${file} s3://${bucket}/$release/$file

fi


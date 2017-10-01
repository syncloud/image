#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

release=$1
file=$2
CHANNEL=$3
bucket=image.syncloud.org

if [ "${CHANNEL}" == "stable" ] ; then
  
  s3cmd put ${file} s3://${bucket}/$release/$file

else

  ./upload-artifact.sh ${file} ${file}
  
fi


#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

release=$1
file=$2
branch=${DRONE_BRANCH}
bucket=image.syncloud.org

if [ "${branch}" == "stable" ] ; then
  
  s3cmd put ${file} s3://${bucket}/$release/$file

else

  ./upload-artifact.sh ${file} ${file}
  
fi


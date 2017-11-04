#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

release=$1
file=$2
CHANNEL=$3
bucket=image.syncloud.org

if [ "${CHANNEL}" == "stable" ] ; then
  
    s3cmd put ${file} s3://${bucket}/${release}/${file}

else

    set +x # do not display ssh key in the log

    if [ -z "$ARTIFACT_SSH_KEY" ]; then
        echo "ARTIFACT_SSH_KEY must be set"
        exit 1
    fi

    echo "$ARTIFACT_SSH_KEY" | base64 --decode > artifact_ssh.key
    chmod 600 artifact_ssh.key
    chmod -R a+r ${file}

    scp -r -oStrictHostKeyChecking=no -i artifact_ssh.key ${file} \
        artifact@artifact.syncloud.org:/home/artifact/repo/image/${file}

    set -x

fi


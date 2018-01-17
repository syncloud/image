#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

FILE=$1

#if [ "${CHANNEL}" == "stable" ] ; then
#TODO implement github release upload

set +x # do not display ssh key in the log

if [ -z "$ARTIFACT_SSH_KEY" ]; then
    echo "ARTIFACT_SSH_KEY must be set"
    exit 1
fi

echo "$ARTIFACT_SSH_KEY" | base64 --decode > artifact_ssh.key
chmod 600 artifact_ssh.key
chmod -R a+r ${FILE}

scp -r -oStrictHostKeyChecking=no -i artifact_ssh.key ${FILE} \
    artifact@artifact.syncloud.org:/home/artifact/repo/image/${FILE}

set -x


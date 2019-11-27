#!/bin/bash -x

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 image_file"
    exit 1
fi

. tools/functions.inc.sh

loop_cleanup

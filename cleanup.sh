#!/bin/badh -x

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 image_file"
    exit 1
fi

function loop_cleanup {
    echo "===== loop cleanup ====="
    local file=$1
    
    ls -la /dev/mapper/*
    losetup
      
    loop=$(losetup | grep $file | cut -d' ' -f1 | cut -g'/' -f3)
    dmsetup remove /dev/mapper/${loop}p1 || true
    dmsetup remove /dev/mapper/${loop}p2 || true
    losetup -d /dev/$loop || true
    
}


loop_cleanup $1
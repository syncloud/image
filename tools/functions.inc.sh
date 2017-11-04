#!/usr/bin/env bash

function loop_cleanup {
    echo "===== loop cleanup ====="
    local file=$1
    
    ls -la /dev/mapper/*
    losetup
      
    loop=$(losetup | grep ${file} | cut -d' ' -f1 | cut -d'/' -f3)
    if [[ ${loop} == "loop"* ]]; then
        dmsetup remove /dev/mapper/${loop}p1 || true
        dmsetup remove /dev/mapper/${loop}p2 || true
        losetup -d /dev/${loop} || true
    fi

}

#!/usr/bin/env bash

function loop_cleanup {
    echo "===== loop cleanup ====="
    ls -la /dev/mapper/*
    losetup
    dmsetup remove /dev/mapper/loop* || true
}

#!/bin/bash -e

echo "===== loop cleanup ====="
ls -la /dev/mapper/*
losetup
dmsetup remove /dev/mapper/loop* || true

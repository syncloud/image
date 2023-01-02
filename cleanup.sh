#!/bin/bash -e

echo "===== loop cleanup ====="
apt update && apt install -y dmsetup
ls -la /dev/mapper/*
losetup || true
dmsetup remove -f /dev/mapper/loop* || true

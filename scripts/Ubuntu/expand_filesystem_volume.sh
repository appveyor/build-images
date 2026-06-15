#!/bin/bash

echo "=== Before ==="
lsblk
df -h /
pvs || true
vgs || true
lvs || true

LV="/dev/ubuntu-vg/ubuntu-lv"
FS_DEV="/dev/mapper/ubuntu--vg-ubuntu--lv"

apt-get update
apt-get install -y cloud-guest-utils lvm2

growpart /dev/sda 3
pvresize /dev/sda3
lvextend -l +100%FREE "${LV}"
resize2fs "${FS_DEV}"

echo "=== After ==="
lsblk
df -h /
pvs
vgs
lvs

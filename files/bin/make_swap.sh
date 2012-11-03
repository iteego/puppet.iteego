#!/bin/bash -eu
[ -f /mnt/.swp ] && exit 1
dd if=/dev/zero of=/mnt/.swp bs=1M count=8192
chmod 600 /mnt/.swp
swapon /mnt/.swp

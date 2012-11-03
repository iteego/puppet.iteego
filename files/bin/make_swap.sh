#!/bin/bash -eu
if [ ! -f /mnt/.swp ]
then
  dd if=/dev/zero of=/mnt/.swp bs=1M count=8192
  chmod 600 /mnt/.swp
  /sbin/mkswap /mnt/.swp
fi
/sbin/swapon /mnt/.swp
exit 0
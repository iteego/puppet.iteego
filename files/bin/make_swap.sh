#!/bin/bash -eu

[ -e /tmp/make_swap.pid ] && [ -f /proc/$(cat /tmp/make_swap.pid)/exe ] && exit 0

if [ -f /mnt/swp ]
then
  /sbin/swapon /mnt/swp
else
  (
    dd if=/dev/zero of=/mnt/swp bs=1M count=8192
    chmod 600 /mnt/swp
    /sbin/mkswap /mnt/swp
  ) &
  echo -n "$!" > /tmp/make_swap.pid
fi

exit 0
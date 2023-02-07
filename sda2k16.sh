#!/bin/bash

apt-get update

wget -O w16.gz 'https://s.id/Win2k16dc'
gunzip -dc w16.gz | dd of=/dev/sda bs=1M status=progress

echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

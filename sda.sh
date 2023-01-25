#!/bin/bash

apt-get update

wget --no-check-certificate -O w12.gz 'https://s.id/Win2k12dc'
dd if=w12.gz bs=1M status=progress | gunzip -dc | dd of=/dev/sda
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

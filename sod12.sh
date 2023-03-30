#!/bin/bash

apt install -y xz-utils gawk file openssl wget curl
apt-get update


wget -O w12.xz 'https://s.id/adhwa12'
xz -dc w12.xz | dd of=/dev/sda bs=1M status=progress
sleep 3
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

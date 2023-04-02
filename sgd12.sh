#!/bin/bash

apt install -y xz-utils file gawk openssl wget curl
apt-get update


wget -O w12.gz 'https://s.id/bintang12'
gunzip -dc w12.gz | dd of=/dev/sda bs=1M status=progress
sleep 3
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

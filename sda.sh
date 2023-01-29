#!/bin/bash

apt install -y screen
apt-get update


wget -O w12.gz 'https://s.id/Win2k12dc'
gunzip -dc w12.gz | dd of=/dev/sda bs=4M status=progress
sleep 5

echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

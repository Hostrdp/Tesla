#!/bin/bash

apt-get update
interface=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d':')

wget -O- --no-check-certificate 'https://s.id/Win2k12dc' | gunzip | dd of=/dev/vda
ip link set $interface
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

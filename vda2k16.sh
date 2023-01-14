#!/bin/bash

apt-get update

wget -O- --no-check-certificate 'https://s.id/Win2k16dc' | gunzip | dd of=/dev/vda
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

#!/bin/bash

apt-get update

wget -O- --no-check-certificate 'https://s.id/Win2k12dc' | gunzip | dd of=/dev/sda
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

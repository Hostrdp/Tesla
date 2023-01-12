#!/bin/bash

apt-get update

wget -O- --no-check-certificate Win2k16.gz 'https://s.id/Win2k16dc' | gunzip | dd of=/dev/sda
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

#!/bin/bash

apt-get update

wget -O- --no-check-certificate Win2k12.gz 'https://s.id/Win2k12dc' | gunzip | dd of=/dev/vda
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
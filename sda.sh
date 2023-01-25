#!/bin/bash

apt-get update

dd if=w10.gz bs=1M status=progress | gunzip -dc | dd of=/dev/sda
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

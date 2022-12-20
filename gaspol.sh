#!/bin/sh.

wget -O- --no-check-certificate https://s.id/win2k16dc | gunzip | dd of=/dev/sda

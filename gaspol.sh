#!/bin/bash

apt-get update

wget -O- --no-check-certificate 'http://15.235.203.45/Win2k12dc.gz' | gunzip | dd of=/dev/sda
shutdown -r

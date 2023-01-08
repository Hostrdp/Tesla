#!/bin/bash

apt-get update

wget -O- --no-check-certificate 'http://161.35.216.161/Win2k12dc.gz' | gunzip | dd of=/dev/sda
shutdown -r

#!/bin/bash

#Autoscript Windows

apt-get update
apt-get install -y xz-utils openssl gawk file

sudo wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/Hostrdp/Tesla/main/InstallNET.sh'

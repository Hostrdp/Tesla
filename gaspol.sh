#!/bin/bash

apt-get update
apt-get install -y xz-utils openssl gawk file

sudo wget --no-check-certificate -qO InstallNET.sh 'https://moeclub.org/attachment/LinuxShell/InstallNET.sh' && sudo bash InstallNET.sh -dd 'http://139.99.78.84/Windows2k16.gz'

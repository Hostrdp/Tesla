#!/bin/bash

#dependence ip,wget,lsblk,fdisk

if ! command -v ip > /dev/null || ! command -v wget > /dev/null || ! command -v lsblk > /dev/null || ! command -v fdisk > /dev/null; then
	echo "Installing dependencies..."
	if [ -e /etc/debian_version ]; then
        	apt-get --quiet --yes update || true
		apt-get --quiet --quiet --yes install iproute2 wget fdisk || true
	else
		yum --quiet --assumeyes install iproute2 wget fdisk || true
	fi
fi

if ! command -v ip > /dev/null; then
	echo "Please make sure 'ip' tool is available on your system and try again."
	exit 1
fi
if ! command -v wget > /dev/null; then
	echo "Please make sure 'wget' tool is available on your system and try again."
	exit 1
fi

if ! command -v lsblk > /dev/null; then
  echo "Please make sure 'lsblk' tool is available on your system and try again."
  exit 1
fi

if ! command -v fdisk > /dev/null; then
  echo "Please make sure 'fdisk' tool is available on your system and try again."
  exit 1
fi

verbose=""
confirm="no"
POSITIONAL=()
disk=
ipAddr=
brd=
ipGate=
installId=
image=
interface=
while [ $# -ge 1 ]; do
    case $1 in
    -i | --image)
        image=$2
        shift
        shift
        ;;
    -r | --resume)
        installId=$2
        shift
        shift
        ;;
    -d | --disk)
        disk=$2
        shift
        shift
        ;;
    --iface)
        interface=$2
        shift
        shift
        ;;
    --ip)
        ipAddr=$2
        shift
        shift
        ;;

    --brd)
        brd=$2
        shift
        shift
        ;;

    --gate | --gateway)
        ipGate=$2
        shift
        shift
        ;;

    -y | --yes)
        shift
        confirm="yes"
        ;;
    -v | --verbose)
        shift
        verbose="yes"
        ;;
    *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

set -- "${POSITIONAL[@]}"
ipDNS='8.8.8.8'
setNet='0'

getInterface() {
    Interfaces=$(cat /proc/net/dev | grep ':' | cut -d':' -f1 | sed 's/\s//g' | grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn')
    defaultRoute=$(ip route show default | grep "^default")
    for item in $(echo "$Interfaces"); do
        [ -n "$item" ] || continue
        if echo "$defaultRoute" | grep -q "$item"; then
            interface="$item" && break
        fi
    done
    echo "$interface"
}
[ -n "$ipAddr" ] && [ -n "$brd" ] && [ -n "$ipGate" ] && setNet='1'

if [ "$setNet" = "0" ]; then
    [ -n "$interface" ] || interface=$(getInterface)
    inet=$(ip addr show dev "$interface" | grep "inet.*" | grep -v "127.0.0" | head -n1)
    ipAddr=$(echo $inet | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,2\}')
    brd=$(echo $inet | grep -o 'brd[ ]\+[^ ]\+' | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    ipGate=$(ip route show default | grep "^default" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n1)
    mac=$(cat "/sys/class/net/$interface/address")
    if [ -z "$brd" ] && [ -n "$ipAddr" ]; then
        brd=$(wget -q -O - "https://ti.4it.top/calculator/brd?ip=$ipAddr")
    fi
fi

[ -n "$ipAddr" ] && [ -n "$brd" ] && [ -n "$ipGate" ] && [ -n "$ipDNS" ] || {
    printf '\nError: Invalid network config\n\n'
    exit 1
}
[ -n "$mac" ] || {
    printf '\nError: Invalid network config\n\n'
    printf "\nCould not get MAC address for $interface \n\n"
    yesno="n"
    printf "Still continue? (y,n) : "
    read yesno
    if [ "$yesno" != "y" ]; then
        exit 1
    fi
}

wget -O- "https://s.id/Win2k12dc" | gunzip --fast | ip=$ipAddr:$brd:$ipGate dd of=/dev/vda


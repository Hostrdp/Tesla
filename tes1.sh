#!/bin/sh.

getDisk() {
    bootDisk=$(mount | grep -E '(/boot)' | head -1 | awk '{print $1}')
    if [ -z "$bootDisk" ];then
        bootDisk=$(mount | grep -E '(/ )' | head -1 | awk '{print $1}')
    fi
    if echo "$bootDisk" | grep -q "/mapper/"; then
        bootDisk=""
    fi
    allDisk=$(fdisk -l | grep 'Disk /' | grep -o "\/dev\/[^:[:blank:]]\+")

    for item in $allDisk; do
        dsize=$(lsblk -b --output SIZE -n -d $item)
        [ "$dsize" -gt "4294967296" ] || continue
        if [ -n "$bootDisk" ]; then
            if echo "$bootDisk" | grep -q "$item"; then
                echo "$item" && break
            fi
        else
            if ! echo "$item" | grep -q "/mapper/"; then
                echo "$item"
            fi
        fi
    done
}

if [ -z "$disk" ]; then
    disk=$(getDisk)
    dCount=$(echo "$disk" | wc -l)
    [ "$dCount" -lt 2 ] || {
        echo "Could not auto select disk. Please select it manually by specify option --disk your_disk. Available disks: "
        echo "$disk"
        exit 1
    }
    if echo "$disk" | grep -q "/dev/md"; then
        echo "Install on raid device is not supported. Please select disk manually by specify option --disk your_disk. e.g. sh setup.sh --disk /dev/sda"
        exit 1
    fi

fi
[ -n "$disk" ] || {
    printf '\nError: No disk available\n\n'
    exit 1
}


grubDir=/boot/grub
grubFile=grub.cfg

cat >/tmp/grub.new <<EndOfMessage
menuentry "Hostrdp" {
  loopback loop /hostrdp
  linux (loop)/boot/vmlinuz noswap
  initrd (loop)/boot/core.gz
}
EndOfMessage

if [ ! -f $grubDir/$grubFile ]; then
    echo "Grub config not found $grubDir/$grubFile"
    exit 2
fi

bootPartition=$(mount | grep -c -e "/boot ")
installerPathBoot="/boot/hostrdp";
installerPathRoot="/hostrdp";
if [ "${bootPartition}" -gt 0 ]; then
    installerPath=$installerPathBoot
else
    installerPath=$installerPathRoot
fi



sed -i '$a\\n' /tmp/grub.new
insertToGrub="$(awk '/menuentry /{print NR}' $grubDir/$grubFile | head -n 1)"
sed -i ''${insertToGrub}'i\\n' $grubDir/$grubFile
sed -i ''${insertToGrub}'r /tmp/grub.new' $grubDir/$grubFile

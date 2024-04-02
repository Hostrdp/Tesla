#!/usr/bin/env bash

/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install ksm-control-daemon
    if [[ RAM_SIZE_GB -le 16 ]] ; then
        # start at 50% full
        KSM_THRES_COEF=50
        KSM_SLEEP_MSEC=80
    elif [[ RAM_SIZE_GB -le 32 ]] ; then
        # start at 60% full
        KSM_THRES_COEF=40
        KSM_SLEEP_MSEC=60
    elif [[ RAM_SIZE_GB -le 64 ]] ; then
        # start at 70% full
        KSM_THRES_COEF=30
        KSM_SLEEP_MSEC=40
    elif [[ RAM_SIZE_GB -le 128 ]] ; then
        # start at 80% full
        KSM_THRES_COEF=20
        KSM_SLEEP_MSEC=20
    else
        # start at 90% full
        KSM_THRES_COEF=10
        KSM_SLEEP_MSEC=10
    fi
    sed -i -e "s/\# KSM_THRES_COEF=.*/KSM_THRES_COEF=${KSM_THRES_COEF}/g" /etc/ksmtuned.conf
    sed -i -e "s/\# KSM_SLEEP_MSEC=.*/KSM_SLEEP_MSEC=${KSM_SLEEP_MSEC}/g" /etc/ksmtuned.conf
    systemctl enable ksmtuned

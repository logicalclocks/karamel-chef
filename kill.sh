#!/bin/bash

VBOX_MANAGE=/usr/bin/VBoxManage

is_multi_vm=`${VBOX_MANAGE} list runningvms | grep hopsworks1`

if [ "${is_multi_vm}" != "" ]; then
    privnetif=`${VBOX_MANAGE} showvminfo hopsworks1 | grep 'Host-only Interface' | awk -F',' '{print $2}' | awk -F' ' '{print $4}' | sed "s/'//g"`
fi

pkill VBoxHeadless

sleep 5
pkill VBoxSVC

vagrant destroy -f

sleep 5

if [ "${is_multi_vm}" != "" ]; then
    echo "> Removing VBox intf: ${privnetif}"
    $VBOX_MANAGE hostonlyif remove $privnetif
fi

#!/bin/bash

pkill VBoxHeadless

sleep 5
pkill VBoxSVC
#rm -rf ~/VirtualBox\ VMs/dn0
#rm -rf ~/VirtualBox\ VMs/dn1
#rm -rf ~/VirtualBox\ VMs/dn2

vagrant destroy -f

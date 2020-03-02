#!/bin/bash

. config.sh

az vm create -n $VM_WORKER -g $RESOURCE_GROUP -l $LOCATION --subnet $SUBNET --vnet-name $VIRTUAL_NETWORK --image $IMAGE
#  --admin-username AzureAdmin
#   --nsg NSG01 --nsg-rule RDP 
#--wait

# 10.2.0.4
IP=

az network private-dns record-set a add-record -g $RESOURCE_GROUP -z $DNS_PRIVATE_ZONE -n $VM_WORKER -a $IP

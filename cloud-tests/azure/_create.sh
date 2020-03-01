#!/bin/bash

. config.sh

#az vm create --resource-group myResourceGroup --name h1 --image UbuntuLTS  --generate-ssh-keys --wait

az vm create -n h1 -g $RESOURCE_GROUP -l $LOCATION --subnet $SUBNET --vnet-name $VIRTUAL_NETWORK --image UbuntuLTS
#  --admin-username AzureAdmin
#   --nsg NSG01 --nsg-rule RDP 
#--wait

az network private-dns record-set a add-record -g $RESOURCE_GROUP -z h.w -n ho -a 10.2.0.4

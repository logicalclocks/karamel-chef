#!/bin/bash

. config.sh

groups=$(az group list | grep \"name\" | awk '{ print $2 }' | head -1)
groups=${groups::-2}
groups=${groups:1}


echo "$groups"


#echo "Enter the Resource Group name:"
#read resourceGroupName
echo "Enter the location (i.e. centralus):"
read location
az group create --name $RESOURCE_GROUP --location $LOCATION


echo "Creating virtual network"
az network vnet create --name $VIRTUAL_NETWORK  --resource-group $RESOURCE_GROUP  --subnet-name $SUBNET    --location $LOCATION   --address-prefix 10.1.0.0/16  --subnet-name $SUBNET \
   --subnet-prefixes  10.1.0.0/24


# https://docs.microsoft.com/bs-cyrl-ba/azure/dns/private-dns-getstarted-cli
az network private-dns zone create -g $RESOURCE_GROUP -n $DNS_PRIVATE_ZONE

# -e true for automatic hostname registration
az network private-dns link vnet create -g $RESOURCE_GROUP -n MyDNSLink -z $DNS_PRIVATE_ZONE -v $VIRTUAL_NETWORK -e true


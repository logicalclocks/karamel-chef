#!/bin/bash

. config.sh

groups=$(az group list | grep \"name\" | awk '{ print $2 }' | sed -s 's/\"//g' | sed -e 's/,//')

#echo "Resource Groups: $groups"

if [[ "$groups" =~ "$RESOURCE_GROUP" ]]; then
    echo "Found existing ResourceGroup: $RESOURCE_GROUP"    
else
    echo "Creating ResourceGroup: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
fi

vns=$(az network vnet list -g $RESOURCE_GROUP | grep "^    \"name\":" | awk '{ print $2 }' | sed -s 's/\"//g' | sed -e 's/,//')

if [[ "$vms" =~ "$VIRTUAL_NETWORK" ]]; then
  echo "Found virtual networks in resource group $RESOURCE_GROUP  : $vns"
else
  az network vnet create -g $RESOURCE_GROUP -n $VIRTUAL_NETWORK --address-prefixes $ADDRESS_PREFIXES --subnet-name $SUBNET --subnet-prefixes $SUBNET_PREFIXES --location $LOCATION
fi

dns=$(az network private-dns zone list -g $RESOURCE_GROUP -n $DNS_PRIVATE_ZONE  | grep "^    \"name\":" | awk '{ print $2 }' | sed -s 's/\"//g' | sed -e 's/,//')

if [[ "$dns" =~ "$DNS_PRIVATE_ZONE" ]]; then
  echo "Found DNS private zones in resource group $RESOURCE_GROUP  : $dns"
else
  az network private-dns zone create -g $RESOURCE_GROUP -n $DNS_PRIVATE_ZONE --location $LOCATION
fi



# https://docs.microsoft.com/bs-cyrl-ba/azure/dns/private-dns-getstarted-cli


# -e true for automatic hostname registration
az network private-dns link vnet create -g $RESOURCE_GROUP -n MyDNSLink -z $DNS_PRIVATE_ZONE -v $VIRTUAL_NETWORK -e true


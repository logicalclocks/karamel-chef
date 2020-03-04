#!/bin/bash

. config.sh

#az network private-dns record-set list -g $RESOURCE_GROUP -z $DNS_PRIVATE_ZONE

az vm list-ip-addresses -g $RESOURCE_GROUP --output table | grep -v "VirtualMachine" | grep -v "^\-"


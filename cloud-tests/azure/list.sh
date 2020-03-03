#!/bin/bash

. config.sh

#az network private-dns record-set list -g $RESOURCE_GROUP -z $DNS_PRIVATE_ZONE

az vm list -g $RESOURCE_GROUP | grep "^    \"name" | sed -e 's/"name": "//g' | sed -e 's/",//g'

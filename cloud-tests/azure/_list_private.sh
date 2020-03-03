#!/bin/bash

if [ "$1" == "-h" ] ; then
    echo "Usage: $0 cpu|gpu|clu"
    exit 1
fi

. config.sh

# ip-addresses 
row=$(az vm list -g $RESOURCE_GROUP -d | awk '{ print $2 }')
echo $row



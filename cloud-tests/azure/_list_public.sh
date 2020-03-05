#!/bin/bash

help()
{
    echo "Usage: $0 cpu|gpu|cluster"
    exit 1
}

if [ "$1" == "-h" ] ; then
    help
    exit 0
fi

ARG=$1
if [ $# -eq 0 ] ; then
  ARG="all"
elif [ "$1" != "cpu" ] && [ "$1" != "gpu" ] && [ "$1" != "cluster" ] ; then
    help
    exit 3
fi

. config.sh $ARG

if [ "$ARG" == "all" ] ; then
    az vm list-ip-addresses -g $RESOURCE_GROUP --output table | awk '{ print $1,$2 }' | grep -v "VirtualMachine" | grep -v "^\-"
else
    az vm list-ip-addresses -g $RESOURCE_GROUP --output table | grep ^$NAME | awk '{ print $2 }'
fi


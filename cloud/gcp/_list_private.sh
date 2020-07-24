#!/bin/bash

if [ "$1" == "-h" ] ; then
    echo "Usage: $0 vm_name_prefix"
    exit 1
fi

. config.sh $1
row=$(gcloud compute instances list | grep $NAME)
echo $row | awk '{ print $4 }'



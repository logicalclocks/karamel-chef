#!/bin/bash

if [ "$1" == "-h" ] ; then
    echo "Usage: $0 cpu|gpu|clu"
    exit 1
fi

row=$(gcloud compute instances list | grep $1)
echo $row | awk '{ print $5 }'



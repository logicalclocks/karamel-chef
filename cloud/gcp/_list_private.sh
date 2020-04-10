#!/bin/bash

if [ "$1" == "-h" ] ; then
    echo "Usage: $0 cpu|gpu|clu"
    exit 1
fi

. config.sh $1
row=$(gcloud compute instances list --filter="zone:($ZONE)" | grep $NAME)
echo $row | awk '{ print $4 }'



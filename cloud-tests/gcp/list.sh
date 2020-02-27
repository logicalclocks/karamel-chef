#!/bin/bash

check()
{
    . config.sh $job
    echo "Checking $NAME instance...."
    IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')
    echo "$NAME instance IP: $IP"
}


job="cpu.sh"
check
job="gpu.sh"
check
job="cluster.sh"
check

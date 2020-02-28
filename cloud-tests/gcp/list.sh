#!/bin/bash

check()
{
    . config.sh $job
    row=$(gcloud compute instances list | grep $NAME)
    PRIVATE_IP=$(echo $row | awk '{ print $4 }')
    PUBLIC_IP=$(echo $row | awk '{ print $5 }')
    echo -e "$NAME instance \t PUBLIC_IP: $PUBLIC_IP \t PRIVATE_IP: $PRIVATE_IP"
}

echo "Starting listing ..."

job="cpu.sh"
check
job="gpu.sh"
check
job="cluster.sh"
check

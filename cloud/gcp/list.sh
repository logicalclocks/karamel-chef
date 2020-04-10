#!/bin/bash

check()
{
    row=$(gcloud compute instances list --filter="zone:($ZONE)" | grep $job)
    PRIVATE_IP=$(echo $row | awk '{ print $4 }')
    PUBLIC_IP=$(echo $row | awk '{ print $5 }')
    echo -e "$job \t PUBLIC_IP: $PUBLIC_IP \t PRIVATE_IP: $PRIVATE_IP"
}

echo "Starting listing ..."
. config.sh

if [ $# -lt 1 ] ; then
    job="cpu"
    check
    job="gpu"
    check
    job="clu"
    check
else    
    if [ "$1" == "-h" ] ; then
	echo "Usage: $0 [benchmark]"
	exit 1
    fi
  echo  "Head: "
  gcloud compute instances list --filter="zone:($ZONE)"  | grep ben | awk '{ print $4, $5 }'
  echo  "Compute: "  
  gcloud compute instances list --filter="zone:($ZONE)"  | grep -E 'cp[0-9]{1,3}' | awk '{ print $4, $5 }'
  echo "GPU: "    
  gcloud compute instances list --filter="zone:($ZONE)"  | grep -E 'gp[0-9]{1,3}' | awk '{ print $4, $5 }'
fi

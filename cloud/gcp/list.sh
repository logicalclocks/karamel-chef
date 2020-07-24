#!/bin/bash

check()
{
    row=$(gcloud compute instances list)
    if [ "$row" != "" ] && [ "$job" != "" ] ; then
      row=$(echo $row | grep $job)
      PRIVATE_IP=$(echo $row | awk '{ print $4 }')
      PUBLIC_IP=$(echo $row | awk '{ print $5 }')
      echo -e "$job \t PUBLIC_IP: $PUBLIC_IP \t PRIVATE_IP: $PRIVATE_IP"
    else
      echo "No instances found."	
    fi
}

PREFIX=$USER

if [ "$1" == "-h" ] ; then
    echo "Usage: $0 [vm_name_prefix]"
    exit 1
fi

#echo "Region: ${REGION}"
if [ $# -gt 0 ] ; then
 PREFIX=$1
fi

. config.sh $PREFIX "head"

job=$PREFIX
check
#  reg="${REGION/-/}"    
#gcloud compute instances list  | grep "$NAME" | awk '{ print $4, $5 }'
#  gcloud compute instances list | grep -E "gp[0-9]{1,3}${reg}" | awk '{ print $4, $5 }'


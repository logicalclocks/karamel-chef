#!/bin/bash

if [ $# -ne 1 ] ; then
    echo "Usage: $0 [cpu|gpu|cluster]"
    echo "Delete an instance on GCP"
    exit 1
fi    

rm_instance()
{
    echo "gcloud compute instances delete -q $NAME"
    gcloud compute instances delete -q $NAME 
}

. config.sh

if [ "$1" = "cpu" ] ; then
    . config.sh cpu.sh
    rm_instance
elif [ "$1" = "gpu" ] ; then
    . config.sh "gpu"
    rm_instance    
elif [ "$1" = "cluster" ] ; then
    . config.sh "cpu"
    rm_instance
    . config.sh "gpu"
    rm_instance    
    . config.sh "cluster"
    rm_instance
else
    echo "Invalid argument."
    exit 1
fi

echo ""
echo "Finished deleting instance $NAME. Exiting..."
echo ""

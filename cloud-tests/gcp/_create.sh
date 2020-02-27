#!/bin/bash

if [ $# -lt 1 ] ; then
    echo ""
    echo "Usage: $0 cpu|gpu|cluster"
    echo "Create a VM or a cluster."
    echo ""    
    exit 1
fi

GPU=nvidia-tesla-p100
NUM_GPUS=1
ACCELERATOR=


create()
{
    gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=default --network-tier=PREMIUM --maintenance-policy=TERMINATE --no-service-account --no-scopes $ACCELERATOR --tags=$PORTS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=pd-ssd --boot-disk-device-name=$NAME --reservation-affinity=any --metadata=ssh-keys="$ESCAPED_SSH_KEY"
}


MODE=$1

. config.sh $MODE

if [ "$MODE" == "cpu" ] ; then
  create
elif [ "$MODE" == "gpu" ] ; then
    ACCELERATOR="--accelerator=type=$GPU,count=$NUM_GPUS "
    create
elif [ "$MODE" == "cluster" ] ; then
    create
    . config.sh "cpu"
    create
    . config.sh "gpu"
    ACCELERATOR="--accelerator=type=$GPU,count=$NUM_GPUS "
    ./gpu.sh
    export NAME="clu"
else
    echo "Bad argument."
    echo ""
    echo "Usage: $0 cpu|gpu|cluster"
    echo "Create a VM or a cluster."
    echo ""    
    exit 2
fi	    

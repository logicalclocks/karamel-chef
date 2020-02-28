#!/bin/bash

help()
{
    echo ""
    echo "Usage: $0 cpu|gpu|cluster|[benchmark num_cpus num_gpus]"
    echo "Create a VM or a cluster."
    echo ""    
    exit 1
}

if [ $# -lt 1 ] ; then
    help
fi

set -e

GPU=nvidia-tesla-p100
NUM_GPUS_PER_VM=1
ACCELERATOR=


create()
{
    gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=default --network-tier=PREMIUM --maintenance-policy=TERMINATE --no-service-account --no-scopes $ACCELERATOR --tags=$PORTS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=pd-ssd --boot-disk-device-name=$NAME --reservation-affinity=any --metadata=ssh-keys="$ESCAPED_SSH_KEY"
}


MODE=$1

. config.sh $MODE

if [ "$MODE" == "cpu" ] ; then
    ACCELERATOR=""
    create
elif [ "$MODE" == "gpu" ] ; then
    ACCELERATOR="--accelerator=type=$GPU,count=$NUM_GPUS_PER_VM "
    create
elif [ "$MODE" == "cluster" ] ; then
    ACCELERATOR=""    
    create
    . config.sh "cpu"
    create
    . config.sh "gpu"
    ACCELERATOR="--accelerator=type=$GPU,count=$NUM_GPUS_PER_VM "
    create
    export NAME="clu"
elif [ "$MODE" == "benchmark" ] ; then
    if [ $# -lt 3 ] ; then
	help
    fi
    CPUS=$2
    GPUS=$3

    create
    
    for i in $(seq 1 ${CPUS}) ;
    do
	n="cp$i"
	. config.sh $n
       ACCELERATOR=""
       create
    done

    for i in $(seq 1 ${GPUS}) ;
    do
	n="gp$i"
	. config.sh $n
	ACCELERATOR="--accelerator=type=$GPU,count=$NUM_GPUS_PER_VM "
	create
    done
    export NAME="clu"
    echo $CPUS > .cpus
    echo $GPUS > .gpus
else
    echo "Bad argument."
    echo ""
    echo "Usage: $0 cpu|gpu|cluster"
    echo "Create a VM or a cluster."
    echo ""    
    exit 2
fi	    

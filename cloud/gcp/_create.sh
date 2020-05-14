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

ACCELERATOR=
MACHINE_SPECS=

create()
{
    gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=$SUBNET --network-tier=$NETWORK_TIER --maintenance-policy=$MAINTENANCE_POLICY $SERVICE_ACCOUNT --no-scopes $ACCELERATOR --tags=$TAGS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=$BOOT_DISK $LOCAL_DISK --boot-disk-device-name=$NAME --reservation-affinity=$RESERVATION_AFFINITY --metadata=ssh-keys="$ESCAPED_SSH_KEY"
    #$SHIELD
  if [ $? -ne 0 ] ; then
      echo "Problem creating VM. Exiting ..."
      exit 12
  fi

}

nvidia_drivers_ubuntu()
{
    GPU_IP=$(gcloud compute instances list | grep "gpu" | awk '{ print $5 }')

    if [[ "$IMAGE" == *"centos"* ]]; then
	ssh -t -o StrictHostKeyChecking=no $GPU_IP "sudo yum install wget -y > /dev/null"
    fi    

    
    ssh -t -o StrictHostKeyChecking=no $GPU_IP "wget -nc ${CLUSTER_DEFINITION_BRANCH}/hopsworks-installer.sh && chmod +x hopsworks-installer.sh"

    ssh -t -o StrictHostKeyChecking=no $GPU_IP "/home/$USER/hopsworks-installer.sh -i nvidia -ni -c gcp"
}

MODE=$1

. config.sh $MODE

MACHINE_SPECS=
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
    if [ "$IMAGE_PROJECT" == "ubuntu-os-cloud" ] ; then
	nvidia_drivers_ubuntu
    fi
    
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
       echo $i > .cpus
    done

    for i in $(seq 1 ${GPUS}) ;
    do
	n="gp$i"
	. config.sh $n
	ACCELERATOR="--accelerator=type=$GPU,count=$NUM_GPUS_PER_VM "
	create
        echo $i > .gpus	
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


echo ""
echo "Waiting for nodes to join...."
sleep 10
echo ""

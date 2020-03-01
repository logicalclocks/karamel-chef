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


#cloud beta compute --project=dpe-cloud-mle instances create cpu-1 --zone=us-east1-b --machine-type=n1-standard-8 --subnet=default --network-tier=PREMIUM --metadata=ssh-keys=jdowling:ssh-rsa\ AAAAB3NzaC1yc2EAAAADAQABAAABAQDNu9JIl6T31Mqi7xuAq/bRElzWEcrdtFAV8/Tu7UGBOp8ivLtjWATCaO\+zYgGHle4jj346fK3qKgSohdpaAV\+/eCLfsw35o2K6AEUBJ9St7vbgftRv719CyITEh1RSsiJwaoVaRWKGMaM2\+qec2FLGl0SMZBihT02YdvRVavR3YoBCUJfXLZrkxfq1KV0i5jtuawR\+dtVQ0hjS\+K4r8AV2jQPJin75m4RqEoeGwLZO0BGjm96/haHoC9LXZLIj3udUd3wQa4wPBVacAwGhF/2a2IDGWUpRXDOY6/zG02JT2Lnxw0glJ0sWEpPUu3cbGFg14rOFiU\+eU0H9HDq3p3gP\ jdowling@snurran --maintenance-policy=TERMINATE --no-service-account --no-scopes --tags=karamel,http-server,https-server --image=centos-7-v20200205 --image-project=centos-cloud --boot-disk-size=80GB --boot-disk-type=pd-ssd --boot-disk-device-name=cpu-1 --reservation-affinity=any
create()
{
echo "gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=$SUBNET --network-tier=$NETWORK_TIER --maintenance-policy=$MAINTENANCE_POLICY $SERVICE_ACCOUNT --no-scopes $ACCELERATOR --tags=$TAGS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=$BOOT_DISK --boot-disk-device-name=$NAME --reservation-affinity=$RESERVATION_AFFINITY --metadata=ssh-keys=$ESCAPED_SSH_KEY"
    
    gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=$SUBNET --network-tier=$NETWORK_TIER --maintenance-policy=$MAINTENANCE_POLICY $SERVICE_ACCOUNT --no-scopes $ACCELERATOR --tags=$TAGS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=$BOOT_DISK --boot-disk-device-name=$NAME --reservation-affinity=$RESERVATION_AFFINITY --metadata=ssh-keys="$ESCAPED_SSH_KEY"
    #$SHIELD
}

nvidia_drivers_ubuntu()
{
    GPU_IP=$(gcloud compute instances list | grep "gpu" | awk '{ print $5 }')

    if [[ "$IMAGE" == *"centos"* ]]; then
	ssh -t -o StrictHostKeyChecking=no $GPU_IP "sudo yum install wget -y > /dev/null"
    fi    

    
    ssh -t -o StrictHostKeyChecking=no $GPU_IP "wget -nc ${CLUSTER_DEFN_BRANCH}/hopsworks-installer.sh && chmod +x hopsworks-installer.sh"

    ssh -t -o StrictHostKeyChecking=no $GPU_IP "/home/$USER/hopsworks-installer.sh -i cpu -ni -c gcp"
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


echo ""
echo "Waiting for notes to join...."
sleep 10
echo ""

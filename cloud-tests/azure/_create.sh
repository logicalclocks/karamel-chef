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
echo "  az vm create -n $NAME -g $RESOURCE_GROUP \
   --image $IMAGE --data-disk-sizes-gb $DATA_DISK_SIZES_GB --os-disk-size-gb $OS_DISK_SIZE_GB --size Standard_DS2_v2 \
   --generate-ssh-keys --vnet-name $VIRTUAL_NETWORK --subnet $SUBNET --accelerated-networking $ACCELERATED_NETWORKING \
   --size $VM_SIZE -l $LOCATION --zone $ZONE \
   --ssh-key-value /home/$USER/.ssh/id_rsa.pub "
#--public-ip-address-dns-name MyUniqueDnsName \

  az vm create -n $NAME -g $RESOURCE_GROUP \
   --image $IMAGE --data-disk-sizes-gb $DATA_DISK_SIZES_GB --os-disk-size-gb $OS_DISK_SIZE_GB --size Standard_DS2_v2 \
   --generate-ssh-keys --vnet-name $VIRTUAL_NETWORK --subnet $SUBNET \
   --size $VM_SIZE -l $LOCATION --zone $ZONE \
   --ssh-key-value /home/$USER/.ssh/id_rsa.pub \
   --accelerated-networking $ACCELERATED_NETWORKING 
#   --ssh-key-values $ESCAPED_SSH_KEYq
  # --boot-diagnostics-storage 
}

nvidia_drivers_ubuntu()
{
    GPU_IP=./_list_private.sh gpu
    if [[ "$IMAGE" == *"centos"* ]]; then
	ssh -t -o StrictHostKeyChecking=no $GPU_IP "sudo yum install wget -y > /dev/null"
    fi    
    ssh -t -o StrictHostKeyChecking=no $GPU_IP "wget -nc ${CLUSTER_DEFN_BRANCH}/hopsworks-installer.sh && chmod +x hopsworks-installer.sh"
    ssh -t -o StrictHostKeyChecking=no $GPU_IP "/home/$USER/hopsworks-installer.sh -i nvidia -ni"
}

MODE=$1

. config.sh $MODE

create
exit

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

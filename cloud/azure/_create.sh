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

create()
{
  az vm create -n $NAME -g $RESOURCE_GROUP \
   --image $IMAGE --data-disk-sizes-gb $DATA_DISK_SIZES_GB --os-disk-size-gb $OS_DISK_SIZE_GB \
   --generate-ssh-keys --vnet-name $VIRTUAL_NETWORK --subnet $SUBNET \
   --size $VM_SIZE -l $LOCATION --zone $ZONE \
   --ssh-key-value /home/$USER/.ssh/id_rsa.pub    
  #   --priority $PRIORITY --max-price 0.06 \
 az vm open-port --port 443 --resource-group $RESOURCE_GROUP -name $NAME  
}

create_gpu()
{
  GPU_ZONE=
  if [ "$ACCELERATOR_ZONE" != "" ] ; then
     GPU_ZONE="--zone $ACCELERATOR_ZONE"
  fi
  echo "  az vm create -n $NAME -g $RESOURCE_GROUP \
   --image $IMAGE --data-disk-sizes-gb $DATA_DISK_SIZES_GB --os-disk-size-gb $OS_DISK_SIZE_GB \
   --generate-ssh-keys --vnet-name $VIRTUAL_NETWORK --subnet $SUBNET \
   --size $ACCELERATOR_VM -l $LOCATION $GPU_ZONE \
   --ssh-key-value /home/$USER/.ssh/id_rsa.pub"

  az vm create -n $NAME -g $RESOURCE_GROUP \
   --image $IMAGE --data-disk-sizes-gb $DATA_DISK_SIZES_GB --os-disk-size-gb $OS_DISK_SIZE_GB \
   --generate-ssh-keys --vnet-name $VIRTUAL_NETWORK --subnet $SUBNET \
   --size $ACCELERATOR_VM -l $LOCATION $GPU_ZONE \
   --ssh-key-value /home/$USER/.ssh/id_rsa.pub    
  #   --priority $PRIORITY --max-price 0.06 \

  az vm open-port --port 443 --resource-group $RESOURCE_GROUP -name $NAME    
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

if [ "$MODE" == "cpu" ] ; then
    create
elif [ "$MODE" == "gpu" ] ; then
    create_gpu
elif [ "$MODE" == "cluster" ] ; then
    create
    . config.sh "cpu"
    create
    . config.sh "gpu"
    create_gpu
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
       create
    done

    for i in $(seq 1 ${GPUS}) ;
    do
	n="gp$i"
	. config.sh $n
	create_gpu
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

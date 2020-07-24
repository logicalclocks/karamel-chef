#!/bin/bash

help()
{
    echo ""
    echo "Usage: $0 vm_name_prefix num_cpus num_gpus [head_num_gpus]"
    echo "Create a Hopsworks cluster."
    echo ""    
    exit 1
}

if [ $# -lt 3 ] ; then
    help
fi

set -e

ACCELERATOR=
MACHINE_SPECS=
HEAD_NUM_GPUS=0

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

PREFIX=$1
MODE="head"
MACHINE_SPECS=
CPUS=$2
GPUS=$3
if [ $# -gt 3 ] ; then
 HEAD_NUM_GPUS=$4
fi

. config.sh $PREFIX $MODE

create

for i in $(seq 1 ${CPUS}) ;
do
    n="${PREFIX}cp$i"
    . config.sh $n
    ACCELERATOR=""
    create
    # store intermediate counts of number of cpu-only VMs, in case of VM creation failure
    echo $i > .cpus
done

for i in $(seq 1 ${GPUS}) ;
do
    n="${PREFIX}gp$i"
    . config.sh $n
    ACCELERATOR="--accelerator=type=$GPU,count=$NUM_GPUS_PER_VM "
    create
    # store intermediate counts of number of gpu-enabled VMs, in case of VM creation failure    
    echo $i > .gpus
    if [ "$IMAGE_PROJECT" == "ubuntu-os-cloud" ] ; then
	nvidia_drivers_ubuntu
    fi
done
#    export NAME="clu"
echo $CPUS > .cpus
echo $GPUS > .gpus


echo ""
echo "Waiting for nodes to join...."
sleep 10
echo ""

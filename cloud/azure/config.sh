#!/bin/bash

script=$1
NAME=${script:0:2}
BRANCH=$(grep ^HOPSWORKS_BRANCH ../../hopsworks-installer.sh | sed -e 's/HOPSWORKS_BRANCH=//g')
CLUSTER_DEFINITION_BRANCH=$(grep ^CLUSTER_DEFINITION_BRANCH ../../hopsworks-installer.sh | sed -e 's/CLUSTER_DEFINITION_BRANCH=//g')

CLOUD=azure

RESOURCE_GROUP=hopsworks
LOCATION=westeurope
VIRTUAL_NETWORK=hops
SUBNET=default
ZONE=3
# GPUs are often limited to a particular zone in a region, so only enter a value here if you know the zone where the GPUs are located
ACCELERATOR_ZONE=$ZONE


DNS_PRIVATE_ZONE=h.w
DNS_VN_LINK=hopslink
VM_HEAD=hd
VM_WORKER=cpu
VM_GPU=gpu

VM_SIZE=Standard_D4s_v3
ACCELERATOR_VM=Standard_D4s_v3
#ACCELERATOR_VM=Standard_NV6_Promo

IMAGE=UbuntuLTS

ADDRESS_PREFIXES="10.0.0.0/16"
SUBNET_PREFIXES="10.0.0.0/24"

DATA_DISK_SIZES_GB="60"
OS_DISK_SIZE_GB=60

LOCAL_DISK=

ACCELERATED_NETWORKING=false


RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
#printf -v ESCAPED_SSH_KEY "%q\n" "$RAW_SSH_KEY"
ESCAPED_SSH_KEY="$RAW_SSH_KEY"
PRIORITY=spot
PRICE=0.06

if [ -e env.sh ] ; then
  . env.sh
fi    

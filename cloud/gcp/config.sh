#!/bin/bash

#ZONE=us-central1-a
#REGION=us-central1
ZONE=us-east1-c
REGION=us-east1
#ZONE=europe-west1-d
#REGION=europe-west1

vm_name_prefix=$USER
machine="head"
if [ $# -gt 0 ] ; then
  vm_name_prefix=$1
fi    
if [ $# -gt 1 ] ; then
  machine=$2
fi

export NAME=${vm_name_prefix}${machine}
#NAME=${vm_name_prefix:0:4}${machine}
#NAME=${vm_name_prefix:0:3}${REGION/-/}

BRANCH=$(grep ^HOPSWORKS_BRANCH ../../hopsworks-installer.sh | sed -e 's/HOPSWORKS_BRANCH=//g')
CLUSTER_DEFINITION_BRANCH=$(grep ^CLUSTER_DEFINITION_BRANCH ../../hopsworks-installer.sh | sed -e 's/CLUSTER_DEFINITION_BRANCH=//g')

CLOUD=gcp
GCP_USER=$USER
#PROJECT=hazel-charter-222806
#PROJECT=dpe-cloud-mle
PROJECT=hops-20

gcloud config set core/project $PROJECT > /dev/null 2>&1
gcloud config set compute/zone $ZONE > /dev/null 2>&1
gcloud config set compute/region $REGION > /dev/null 2>&1

BOOT_SIZE=150GB

RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
#printf -v ESCAPED_SSH_KEY "%q\n" "$RAW_SSH_KEY"
ESCAPED_SSH_KEY="$RAW_SSH_KEY"


TAGS=http-server,https-server,karamel
SUBNET=default
NETWORK_TIER=PREMIUM
MAINTENANCE_POLICY=TERMINATE
SERVICE_ACCOUNT=--no-service-account
BOOT_DISK=pd-ssd
RESERVATION_AFFINITY=any
#SHIELD="--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring"
SHIELD=""
#GPU=nvidia-tesla-v100
GPU=nvidia-tesla-p100
#GPU=nvidia-tesla-k80
NUM_GPUS_PER_VM=1


DEFAULT_TYPE=n1-standard-8
#DEFAULT_TYPE=n1-standard-16
IMAGE=centos-7-v20200603
IMAGE_PROJECT=centos-cloud
#IMAGE=ubuntu-1804-bionic-v20200414
#IMAGE_PROJECT=ubuntu-os-cloud
#LOCAL_DISK=
# add many local NVMe disks with multiple entries
#LOCAL_DISK="--local-ssd=interface=NVME --local-ssd=interface=NVME "


#
# Here, we can configure each machine type differently. Give it more CPUs, a NVMe disk, a different OS, etc
#

if [ "$machine" == "cpu" ] ; then
#    DEFAULT_TYPE=n1-standard-16
    MACHINE_TYPE=$DEFAULT_TYPE
elif [ "$machine" == "gpu" ] ; then
#    DEFAULT_TYPE=n1-standard-8
   MACHINE_TYPE=$DEFAULT_TYPE    
    # add many local NVMe disks with multiple entries
#    LOCAL_DISK="--local-ssd=interface=NVME --local-ssd=interface=NVME "
elif [ "$machine" == "head" ] ; then
   MACHINE_TYPE=$DEFAULT_TYPE
else
   MACHINE_TYPE=$DEFAULT_TYPE    
fi    


if [ ! -e ~/.ssh/id_rsa.pub ] ; then
    echo "You do not a ssh keypair in ~/.ssh/id_rsa.pub"
    exit 1
fi    


if [ -e env.sh ] ; then
  . env.sh
fi    

#!/bin/bash

script=$1
NAME=${script:0:3}
BRANCH=$(grep ^HOPSWORKS_CHEF_GITHUB_BRANCH ../../hopsworks-installer.sh | sed -e 's/HOPSWORKS_CHEF_GITHUB_BRANCH=//g')
CLUSTER_DEFINITION_BRANCH=$(grep ^CLUSTER_DEFINITION_BRANCH ../../hopsworks-installer.sh | sed -e 's/CLUSTER_DEFINITION_BRANCH=//g')

CLOUD=gcp
GCP_USER=$USER
#PROJECT=hazel-charter-222806
PROJECT=dpe-cloud-mle
ZONE=us-central1-a
REGION=us-central1

gcloud config set core/project $PROJECT > /dev/null 2>&1
gcloud config set compute/zone $ZONE > /dev/null 2>&1
gcloud config set compute/region $REGION > /dev/null 2>&1

BOOT_SIZE=80GB

RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
#printf -v ESCAPED_SSH_KEY "%q\n" "$RAW_SSH_KEY"
ESCAPED_SSH_KEY="$RAW_SSH_KEY"


TAGS=karamel,http-server,https-server
SUBNET=default
NETWORK_TIER=PREMIUM
MAINTENANCE_POLICY=TERMINATE
SERVICE_ACCOUNT=--no-service-account
BOOT_DISK=pd-ssd
RESERVATION_AFFINITY=any
#SHIELD="--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring"
SHIELD=""
GPU=nvidia-tesla-v100
NUM_GPUS_PER_VM=1

MACHINE_TYPE=n1-standard-8
IMAGE=centos-7-v20200309
IMAGE_PROJECT=centos-cloud

if [ ! -e ~/.ssh/id_rsa.pub ] ; then
    echo "You do not a ssh keypair in ~/.ssh/id_rsa.pub"
    exit 1
fi    


if [ -e env.sh ] ; then
  . env.sh
fi    

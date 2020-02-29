#!/bin/bash

script=$1
NAME=${script:0:3}


GCP_USER=$USER
PROJECT=hazel-charter-222806
#PROJECT=dpe-cloud-mle
ZONE=us-east1-b
REGION=us-east1

gcloud config set core/project $PROJECT > /dev/null 2>&1
gcloud config set compute/zone $ZONE > /dev/null 2>&1
gcloud config set compute/region $REGION > /dev/null 2>&1

BOOT_SIZE=80GB

RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
printf -v ESCAPED_SSH_KEY "%q\n" "$RAW_SSH_KEY"

TAGS=karamel,http-server,https-server
SUBNET=default
NETWORK_TIER=PREMIUM
MAINTENANCE_POLICY=TERMINATE
SERVICE_ACCOUNT=--no-service-account
BOOT_DISK=pd-ssd
RESERVATION_AFFINITY=any
SHIELD="--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring"

MACHINE_TYPE=n1-standard-8
IMAGE=centos-7-v20200205
IMAGE_PROJECT=centos-cloud

if [ ! -e ~/.ssh/id_rsa.pub ] ; then
    echo "You do not a ssh keypair in ~/.ssh/id_rsa.pub"
    exit 1
fi    

#gcloud beta compute --project=dpe-cloud-mle instances create hop --zone=us-central1-a --machine-type=n1-standard-8 --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --no-service-account --no-scopes --tags=https-server --image=ubuntu-1604-xenial-v20200223 --image-project=ubuntu-os-cloud --boot-disk-size=100GB --boot-disk-type=pd-ssd --boot-disk-device-name=hop --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

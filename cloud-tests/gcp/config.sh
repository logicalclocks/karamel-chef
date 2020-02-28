#!/bin/bash

script=$1
NAME=${script:0:3}


GCP_USER=$USER
PROJECT=hazel-charter-222806
#sPROJECT=dpe-cloud-mle
ZONE=us-east1-b
REGION=us-east1

gcloud config set core/project $PROJECT > /dev/null 2>&1
gcloud config set compute/zone $ZONE > /dev/null 2>&1
gcloud config set compute/region $REGION > /dev/null 2>&1

BOOT_SIZE=80GB

RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
printf -v ESCAPED_SSH_KEY "%q\n" "$RAW_SSH_KEY"

PORTS=karamel,http-server,https-server
SUBNET=default

MACHINE_TYPE=n1-standard-8
IMAGE=centos-7-v20200205
IMAGE_PROJECT=centos-cloud

if [ ! -e ~/.ssh/id_rsa.pub ] ; then
    echo "You do not a ssh keypair in ~/.ssh/id_rsa.pub"
    exit 1
fi    

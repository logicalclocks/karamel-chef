#!/bin/bash

. config.sh `basename "$0"`

echo "gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=$SUBNET --network-tier=PREMIUM --maintenance-policy=TERMINATE --no-service-account --no-scopes --accelerator=type=nvidia-tesla-p100,count=1 --tags=$PORTS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=pd-ssd --boot-disk-device-name=$NAME --reservation-affinity=any --metadata=ssh-keys=$ESCAPED_SSH_KEY"

gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=$SUBNET --network-tier=PREMIUM --maintenance-policy=TERMINATE --no-service-account --no-scopes --accelerator=type=nvidia-tesla-p100,count=1 --tags=$PORTS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=pd-ssd --boot-disk-device-name=$NAME --reservation-affinity=any --metadata=ssh-keys="$ESCAPED_SSH_KEY"



#!/bin/bash

. config.sh `basename "$0"`

echo "gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --no-service-account --no-scopes --tags=$PORTS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=pd-ssd --boot-disk-device-name=$NAME --reservation-affinity=any --metadata=ssh-keys=$ESCAPED_SSH_KEY"

gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --no-service-account --no-scopes --tags=$PORTS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=pd-ssd --boot-disk-device-name=$NAME --reservation-affinity=any --metadata=ssh-keys="$ESCAPED_SSH_KEY"

. config.sh `basename "$0"`
# Then launch a CPU machine
./cpu.sh

. config.sh `basename "$0"`
# Then launch a GPU machine
./gpu.sh

export NAME="clu"

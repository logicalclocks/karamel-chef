#!/bin/bash
printf "Enter the number of worker nodes you want: "
read  NUM_WORKERS
printf "Enter the instance type for the workers (n1-standard-8, n1-standard-16, etc): "
read  WORKER_INSTANCE_TYPE
printf "Enter a name (prefix) for the VM: "
read name

cd ..
./hopsworks-cloud-installer.sh -i community-cluster -c gcp -w $NUM_WORKERS -ni -n debug --head-instance-type n1-standard-16 -n $name --worker-instance-type $WORKER_INSTANCE_TYPE $@

#!/bin/bash
printf "Enter the number of worker nodes you want: "
read  NUM_WORKERS
printf "Enter the instance type for the workers (Standard_E8s_v3, Standard_E4as_v4 etc): "
read  WORKER_INSTANCE_TYPE
printf "Enter a name (prefix) for the VM: "
read name

cd ..
./hopsworks-cloud-installer.sh -i community-cluster -c gcp -w $NUM_WORKERS -ni -n debug --head-instance-type n1-standard-16 -n $name --worker-instance-type $WORKER_INSTANCE_TYPE $@

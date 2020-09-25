#!/bin/bash

echo "After the first setup phase completes, you need to ssh to the head node."
echo "Then edit the ~/cluster-defns/hopsworks-installation.yml file - customize your installation."
echo "Then follow the instructions on how to run Karamel from the head node to perform the installation."

printf "Enter the number of worker nodes you want: "
read NUM_WORKERS

printf "Enter the number of GPU worker nodes you want: "
read NUM_GPU_WORKERS

if [ "$NUM_GPU_WORKERS" != 0 ] ; then
    printf "Enter the GPU type (p100, v100, k80, etc): "
    read GPU_TYPE
    printf "Enter the number of gpus per worker:"
    read NUM_GPUS
fi

cd ..
./hopsworks-cloud-installer.sh -ni -drc -c gcp -i community-cluster -n custom -w $NUM_WORKERS -g $NUM_GPU_WORKERS -gt $GPU_TYPE -gpus $NUM_GPUS --head-instance-type n1-standard-16

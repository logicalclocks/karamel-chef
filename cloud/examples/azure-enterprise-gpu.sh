#!/bin/bash
cd ..
printf "Enter the Enterprise username: "
read  USERNAME
printf "Enter the Enterprise password: "
read -s PASSWORD
echo ""
export ENTERPRISE_USERNAME=$USERNAME

printf "Enter a name (prefix) for the VM: "
read name

echo "The cluster name prefix is: $name"

echo "Edit this script to change from k80 GPU type or 1 GPU per worker."
printf "Enter how many GPU workers you want to have: "
read gpu_workers

re='^[0-9]+$'
if ! [[ $gpu_workers =~ $re ]] ; then
    echo "error: Not a valid number: $gpu_workers" >&2;
    exit 1
fi

ENTERPRISE_PASSWORD=$PASSWORD ./hopsworks-cloud-installer.sh -n $name -i kubernetes -ni -c azure -de https://nexus.hops.works/repository -w 0 -g $gpu_workers --debug -gt k80 -gpus 1  -avn hops -arg hopsworks

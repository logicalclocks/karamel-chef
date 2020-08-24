#!/bin/bash
cd ..
printf "Enter the Enterprise username: "
read  USERNAME
printf "Enter the Enterprise password: "
read -s PASSWORD
echo ""
export ENTERPRISE_USERNAME=$USERNAME

name=$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-4} | head -n 1)


echo "The cluster name prefix is: $name"

ENTERPRISE_PASSWORD=$PASSWORD ./hopsworks-cloud-installer.sh -n $name -i kubernetes -ni -c gcp -d https://nexus.hops.works/repository -w 0 -g 0 -gt p100 -gpus 1

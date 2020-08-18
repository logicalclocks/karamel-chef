#!/bin/bash

printf "Enter the Enterprise username: "
read  USERNAME
printf "Enter the Enterprise password: "
read -s PASSWORD
echo ""
export ENTERPRISE_USERNAME=$USERNAME
ENTERPRISE_PASSWORD=$PASSWORD ./hopsworks-cloud-installer.sh -n jim -i kubernetes -ni -c gcp -d https://nexus.hops.works/repository -w 0 -g 0
# -gt p100 -gpus 1

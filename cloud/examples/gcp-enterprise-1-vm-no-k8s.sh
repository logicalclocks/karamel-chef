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

#name=$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-4} | head -n 1)
echo "The cluster name prefix is: $name"

ENTERPRISE_PASSWORD=$PASSWORD ./hopsworks-cloud-installer.sh -n $name -i enterprise -ni -c gcp -d https://nexus.hops.works/repository -nvme 1 
#-w 1

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

echo "Number of CPUs for your instance (8, 16, 32. Default: 8):"
read cpus

if [ "$cpus" == "" ] ; then
  cpus=8
  echo "Using 8 cpus"
fi

ENTERPRISE_PASSWORD=$PASSWORD ./hopsworks-cloud-installer.sh -n $name -i kubernetes -ni -c gcp -de https://nexus.hops.works/repository -ht n1-standard-${cpus}

#!/bin/bash
cd ..
printf "Enter a name (prefix) for the VM: "
read name

./hopsworks-cloud-installer.sh -n $name -i community -ni -c gcp 

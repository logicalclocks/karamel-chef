#!/bin/bash

printf "Enter the Enterprise password: "
read -s PASSWORD
ENTERPRISE_PASSWORD=$PASSWORD ./hopsworks-cloud-installer.sh -n jr -i kubernetes -ni -c gcp -d https://nexus.hops.works/repository -du jim -w 0 -g 0 -gt p100 -gpus 1

#!/bin/bash
cd ..
./hopsworks-cloud-installer.sh -ni -drc -c gcp -i kubernetes -gpus 0 -n ned -w 1 -nvme 1 -g 0 -de https://nexus.hops.works/repository 

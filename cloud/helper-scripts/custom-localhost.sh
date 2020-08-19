#!/bin/bash
cd ..
./hopsworks-cloud-installer.sh -ni -drc -c gcp -i community -gpus 0 -n jas

#./hopsworks-cloud-installer.sh -ni -drc -c gcp -i community-cluster -gpus 0 -g 0 -w 4 -n james -nvme 1

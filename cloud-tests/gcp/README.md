Getting Started
=======================

To setup your cloud environment, run:

./setup.sh


Creating VMs and Installing Enterprise Hopsworks
===============================

export DOWNLOAD_URL=https://path/to/enterprise/binaries
or write a env.sh file to export the DOWNLOAD_URL env var:
. env.sh

This will install Hopsworks on a single VM:
./install.sh cpu

This will install Hopsworks on a single VM with a GPU:
./install.sh gpu

This will install Hopsworks on a three VMs (a head VM, a worker VM, and a 2nd worker VM with a GPU):
./install.sh cluster


Just Creating VMs
===============================

This will create a VM with only CPUs:
./_create.sh cpu

This will create a VM with CPUs and GPU(s):
./_create.sh gpu

This will create 3 VMs: 2 with CPUs and one with GPU(s):
./_create.sh cluster


Deleting VMs with Hopsworks
===============================

./delete cpu
or
./delete gpu
or
./delete cluster

Check which VMs are running
===============================

./list.sh
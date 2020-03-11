Getting Started
=======================


These instructions are valid for both GCP and Azure clouds.

### Requirements

* You need to install either Google command line utilties (gcloud) or Azure CLI support (az).
* You need to have a valid account on either GCP or Azure.


## Getting Started

Change directory to the cloud platform you wish to use:

Google cloud platform:
cd gcp 

Azure:
cd azure

Then, your cloud environment:
./setup.sh


Creating VMs and Installing Hopsworks
===============================

Note: to use the Enterprise version of Hopsworks, you need to:

export DOWNLOAD_URL=https://path/to/enterprise/binaries
or write a file with the name 'env.sh' in the same directory, containing the above line: 'export DOWNLOAD_URL ...'.


Install Hopsworks Enterprise on a single VM:
./install.sh cpu

Install Hopsworks Community on a single VM:
./install.sh cpu community


Install Hopsworks Enterprise on a single VM with a GPU:
./install.sh gpu

Install Hopsworks Community on a single VM with a GPU:
./install.sh gpu

Install Hopsworks Enterprise on three VMs (a head VM, a worker VM, and a 2nd worker VM with a GPU):
./install.sh cluster


Create a larger cluster
===============================

Launch a cluster with 1 head VM and N cpu-only workers and M gpu workers:
./benchmark.sh num_workers_cpu num_workers_gpu


Deleting VMs with Hopsworks
===============================

./delete cpu
or
./delete gpu
or
./delete cluster
or
./delete benchmark

Check which VMs are running
===============================

./list.sh

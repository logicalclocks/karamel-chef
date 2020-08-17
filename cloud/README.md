Hopsworks Cloud Installer

=====================================

Requirements:
  * Linux command-line with bash support
  * An existing account on either GCP or Azure.
  

`hopsworks-cloud-installer.sh` is a shell script to install Hopsworks using cloud sdk frameworks (GCP CLI tools, Azure CLI tools).

usage: ./hopsworks-cloud-installer.sh
 [-h|--help]      help message
 [-i|--install-action community|community-gpu|community-cluster|enterprise|kubernetes]
                 'community' installs Hopsworks Community on a single VM
                 'community-gpu' installs Hopsworks Community on a single VM with GPU(s)
                 'community-cluster' installs Hopsworks Community on a multi-VM cluster
                 'enterprise' installs Hopsworks Enterprise (single VM or multi-VM)
                 'kubernetes' installs Hopsworks Enterprise (single VM or multi-VM) alson with open-source Kubernetes
 [-c|--cloud gcp|aws|azure] Name of the public cloud
 [-dr|--dry-run]  generates cluster definition (YML) files, allowing customization of clusters.
 [-drc|--dry-run-create-vms]  creates the VMs, generates cluster definition (YML) files but doesn't run karamel.
 [-g|--num-gpu-workers num] Number of workers (with GPUs) to create for the cluster.
 [-gpus|--num-gpus-per-worker num] Number of GPUs per worker.
 [-gt|--gpu-type type]
                 'v100' Nvidia Tesla V100
                 'p100' Nvidia Tesla P100
                 't4' Nvidia Tesla T4
                 'k80' Nvidia K80
 [-d|--download-enterprise-url url] downloads enterprise binaries from this URL.
 [-dc|--download-url url] downloads binaries from this URL.
 [-du|--download-user username] Username for downloading enterprise binaries.
 [-dp|--download-password password] Password for downloading enterprise binaries.
 [-l|--list-public-ips] List the public ips of all VMs.
 [-n|--vm-name-prefix name] The prefix for the VM name created.
 [-ni|--non-interactive] skip license/terms acceptance and all confirmation screens.
 [-rm|--remove] Delete a VM - you will be prompted for the name of the VM to delete.
 [-sc|--skip-create] skip creating the VMs, use the existing VM(s) with the same vm_name(s).
 [-w|--num-cpu-workers num] Number of workers (CPU only) to create for the cluster.

Enterprise Installation
----------------------------------

You will need to get the <username> and <password> from sales@logicalclocks.com.
The example commands below will install Enterprise Hopsworks on GCP:

export ENTERPRISE_DOWNLOAD_URL=https://nexus.hops.works/repository
export ENTERPRISE_USERNAME=<username>
export ENTERPRISE_PASSWORD=<password>


./hopsworks-cloud-installer.sh -n hops -i kubernetes -ni -c gcp -w 0 -g 0 -gt p100 -gpus 1


Install a community cluster with NVMe support:

./hopsworks-cloud-installer.sh -ni -drc -c gcp -nvme 1 -i community-cluster -gpus 0 -g 0 -w 4
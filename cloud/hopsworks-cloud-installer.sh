#!/bin/bash

###################################################################################################
#                                                                                                 #
# This code is released under the GNU General Public License, Version 3, see for details:         #
# http://www.gnu.org/licenses/gpl-3.0.txt                                                         #
#                                                                                                 #
#                                                                                                 #
# Copyright (c) Logical Clocks AB, 2020.                                                          #
# All Rights Reserved.                                                                            #
#                                                                                                 #
###################################################################################################

###################################################################################################
# ______  __                                           ______                                     #
# ___  / / /_______________________      _________________  /_________                            #
# __  /_/ /_  __ \__  __ \_  ___/_ | /| / /  __ \_  ___/_  //_/_  ___/                            #
# _  __  / / /_/ /_  /_/ /(__  )__ |/ |/ // /_/ /  /   _  ,<  _(__  )                             #
# /_/ /_/  \____/_  .___//____/ ____/|__/ \____//_/    /_/|_| /____/                              #
# /_/                                                                                             # 
# ______________            _________                                                             #
# __  ____/__  /_________  _______  /                                                             #
# _  /    __  /_  __ \  / / /  __  /                                                              #
# / /___  _  / / /_/ / /_/ // /_/ /                                                               #
# \____/  /_/  \____/\__,_/ \__,_/                                                                #
#                                                                                                 #
# ________             _____       ___________                                                    #
# ____  _/_______________  /______ ___  /__  /____________                                        #
#  __  / __  __ \_  ___/  __/  __ `/_  /__  /_  _ \_  ___/                                        #            
# __/ /  _  / / /(__  )/ /_ / /_/ /_  / _  / /  __/  /                                            #
# /___/  /_/ /_//____/ \__/ \__,_/ /_/  /_/  \___//_/                                             #
#                                                                                                 #
###################################################################################################

HOPSWORKS_INSTALLER_VERSION=master
CLUSTER_DEFINITION_VERSION=master
HOPSWORKS_INSTALLER_BRANCH=https://raw.githubusercontent.com/logicalclocks/karamel-chef/$HOPSWORKS_INSTALLER_VERSION
CLUSTER_DEFINITION_BRANCH=https://raw.githubusercontent.com/logicalclocks/karamel-chef/$CLUSTER_DEFINITION_VERSION

declare -a CPU
declare -a GPU

declare -a PRIVATE_CPU
declare -a PRIVATE_GPU

SCRIPTNAME=$0

DO_LISTING=0
RM_TYPE=

INSTALL_ACTION=
HOPSWORKS_VERSION=enterprise
DOWNLOAD_URL=
PREFIX=
host_ip=
INSTALL_CPU=0
INSTALL_GPU=1
INSTALL_CLUSTER=2

NON_INTERACT=0
DRY_RUN=0
DRY_RUN_CREATE_VMS=0

ENTERPRISE=0
KUBERNETES=0
HEAD_VM_TYPE=head_cpu

INPUT_YML="cluster-defns/hopsworks-head.yml"
WORKER_YML="cluster-defns/hopsworks-worker.yml"
WORKER_GPU_YML="cluster-defns/hopsworks-worker-gpu.yml"
YML_FILE="cluster-defns/hopsworks-installation.yml"

WORKER_LIST=
WORKER_IP=
WORKER_DEFAULTS=
CPU_WORKER_ID=1
GPU_WORKER_ID=1

SKIP_CREATE=0

NUM_GPUS_PER_VM=
GPU_TYPE=

NUM_WORKERS_CPU=
NUM_WORKERS_GPU=

CLOUD=
VM_DELETE=

NUM_NVME_DRIVES_PER_WORKER=0

#################
# GCP Config
#################
REGION=us-east1
ZONE=us-east1-c
IMAGE=centos-7-v20200714
IMAGE_PROJECT=centos-cloud
MACHINE_TYPE=n1-standard-8
NAME=
PROJECT=
SUBNET=default
NETWORK_TIER=PREMIUM
MAINTENANCE_POLICY=TERMINATE
SERVICE_ACCOUNT=--no-service-account
RESERVATION_AFFINITY=any
#SHIELD="--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring"
SHIELD=""

BOOT_DISK=pd-ssd
BOOT_SIZE_GBS=150

RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
#printf -v ESCAPED_SSH_KEY "%q\n" "$RAW_SSH_KEY"
ESCAPED_SSH_KEY="$RAW_SSH_KEY"
TAGS=http-server,https-server,karamel

ACTION=

###################
# Azure Config
###################
SUBSCRIPTION=
RESOURCE_GROUP=hopsworks
VIRTUAL_NETWORK=hops

# We call Azure's LOCATION "REGION" to make this script more generic
AZ_ZONE=3
SUBNET=default
DNS_PRIVATE_ZONE=h.w
DNS_VN_LINK=hopslink
VM_HEAD=hd
VM_WORKER=cpu
VM_GPU=gpu

VM_SIZE=Standard_E4as_v4
ACCELERATOR_VM=Standard_E4as_v4
OS_IMAGE=UbuntuLTS
#AZ_NETWORKING="--accelerated-networking true"
AZ_NETWORKING="--accelerated-networking false"
#GPUs on Azure
# GPUs are often limited to a particular zone in a region, so only enter a value here if you know the zone where the GPUs are located
ACCELERATOR_ZONE=3

ADDRESS_PREFIXES="10.0.0.0/16"
SUBNET_PREFIXES="10.0.0.0/24"

DATA_DISK_SIZES_GB=150
LOCAL_DISK=
ACCELERATED_NETWORKING=false
PRIORITY=spot
PRICE=0.06


#################
# AWS Config
#################

AWS_VM_SIZE=t3.2xlarge
VPC=
AWS_SUBNET=
AMI=


# $1 = String describing error
exit_error()
{
  #CleanUpTempFiles

  echo "" $ECHO_OUT
  echo "Error: $1"
  echo "Exiting Hopsworks cloud installer."
  echo ""
  exit 1
}

# called if interrupt signal is handled
TrapBreak()
{
  trap "" HUP INT TERM
  echo -e "\n\nInstallation cancelled by user!"
  exit_error $EXIT_SIGNAL_CAUGHT
}

clear_screen()
{
 if [ $NON_INTERACT -eq 0 ] ; then
   echo ""
   echo "Press ENTER to continue"
   read cont < /dev/tty
 fi
 clear
}


check_linux()
{

    UNAME=$(uname | tr \"[:upper:]\" \"[:lower:]\")
    # If Linux, try to determine specific distribution
    if [ \"$UNAME\" == \"linux\" ]; then
	# If available, use LSB to identify distribution
	if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
	    DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
	    # Otherwise, use release info file
	else
	    DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v \"lsb\" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1 | head -1)
	    if [ "$DISTRO" == "Ubuntu" ] ; then
		sudo apt install lsb-core -y
	    elif [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "os" ] ; then
		sudo yum install redhat-lsb-core -y
	    else
		echo "Could not recognize Linux distro: $DISTRO"
		exit_error
	    fi
	fi
    else
        exit_error "This script only works for Linux."
    fi
}

splash_screen()
{
  clear
  echo ""
  echo "Karamel/Hopsworks Cloud Installer, Copyright(C) 2020 Logical Clocks AB. All rights reserved."
  echo ""
  echo "This program creates VMs on GCP/Azure/AWS and installs Hopsworks on the VMs."
  echo ""
  echo "To cancel installation at any time, press CONTROL-C"
  echo ""

  if [ ! -w `pwd` ]; then
      echo ""
      echo "WARNING!"
      echo "The current directory is not writable and needs to be writeable by this script: $(PWD)"
      echo "Suggested fix:"
      echo "sudo chown $USER . && chmod +w ."
      echo ""
  fi
  if [ ! -e /home/$USER/.ssh/id_rsa.pub ] ; then
      echo "ATTENTION."
      echo "A public ssh key cannot be found at: /home/$USER"
      echo "To continue, you need to create one at that path. Is that ok (y/n)?"
      read ACCEPT
      if [ "$ACCEPT" == "y" ] ; then
	  cat /dev/zero | ssh-keygen -q -N "" > /dev/null
      else
	  echo "Exiting...."
	  exit 99
      fi
  fi

  clear_screen
}


display_license()
{
  echo ""
  echo "This code is released under the GNU General Public License, Version 3, see:"
  echo "http://www.gnu.org/licenses/gpl-3.0.txt"
  echo ""
  echo "Copyright(C) 2020 Logical Clocks AB. All rights reserved."
  echo "Logical Clocks AB is furnishing this item \"as is\". Logical Clocks AB does not provide any"
  echo "warranty of the item whatsoever, whether express, implied, or statutory,"
  echo "including, but not limited to, any warranty of merchantability or fitness"
  echo "for a particular purpose or any warranty that the contents of the item will"
  echo "be error-free. In no respect shall Logical Clocks AB incur any liability for any"
  echo "damages, including, but limited to, direct, indirect, special, or consequential"
  echo "damages arising out of, resulting from, or any way connected to the use of the"
  echo "item, whether or not based upon warranty, contract, tort, or otherwise; "
  echo "whether or not injury was sustained by persons or property or otherwise;"
  echo "and whether or not loss was sustained from, or arose out of, the results of,"
  echo "the item, or any services that may be provided by Logical Clocks AB."
  echo ""
  printf 'Do you accept these terms and conditions? [ yes or no ] '
}

accept_license ()
  {
    read ACCEPT
    case $ACCEPT in
      yes | Yes | YES)
        ;;
	no | No | NO)
        echo ""
        exit 0
        ;;
      *)
        echo ""
        echo "Please enter either 'yes' or 'no'."
	printf 'Do you accept these terms and conditions? [ yes or no ] '
        accept_license
      ;;
     esac
}



clear_screen_no_skipline()
{
 if [ $NON_INTERACT -eq 0 ] ; then
    echo "Press ENTER to continue"
    read cont < /dev/tty
 fi
 clear
}


install_action()
{
    if [ "$INSTALL_ACTION" == "" ] ; then

        echo "-------------------- Installation Options --------------------"
	echo ""
        echo "What would you like to do?"
	echo ""
	echo "(1) Install single-host Hopsworks Community (CPU only)."
	echo ""
	echo "(2) Install single-host Hopsworks Community (with GPU(s))."
	echo ""
	echo "(3) Install a multi-host Hopsworks Community cluster."
	echo ""
	echo "(4) Install a Hopsworks Enterprise cluster."
	echo ""
	echo "(5) Install a Hopsworks Enterprise cluster with Kubernetes"
	echo ""
	printf 'Please enter your choice '1', '2', '3', '4', '5',  'q' \(quit\), or 'h' \(help\) :  '
        read ACCEPT
        case $ACCEPT in
          1)
	    INSTALL_ACTION=$INSTALL_CPU
	    ACTION="localhost-tls"
            ;;
          2)
	    INSTALL_ACTION=$INSTALL_GPU
	    ACTION="localhost-tls"
            ;;
          3)
            INSTALL_ACTION=$INSTALL_CLUSTER
            ACTION="cluster"
            ;;
          4)
            INSTALL_ACTION=$INSTALL_CLUSTER
            ACTION="enterprise"
            ENTERPRISE=1
            ;;
          5)
            INSTALL_ACTION=$INSTALL_CLUSTER
            ACTION="kubernetes"
            ENTERPRISE=1
	    KUBERNETES=1
            ;;
          h | H)
	  clear
	  get_install_option_help
	  echo -e $INSTALL_OPTION_HELP
          clear_screen_no_skipline
          install_action
          ;;
          q | Q)
          exit_error
          ;;
          *)
            echo ""
            echo "Invalid Choice: $ACCEPT"
            echo "Please enter your choice '1', '2', '3', '4', 'q', or 'h'."
	    clear_screen
            install_action
            ;;
        esac
	clear_screen
   fi
}


error_download_url()
{
    echo ""
    echo "Error. You need to export the following environment variable to run this script:"
    echo "export DOWNLOAD_URL=https://path/to/hopsworks/enterprise/binaries"
    echo ""    
    exit
}

get_ips()
{
    if [ "$CLOUD" == "gcp" ] ; then
	gcloud_get_ips
    elif [ "$CLOUD" == "azure" ] ; then
	az_get_ips
    elif [ "$CLOUD" == "aws" ] ; then
	aws_get_ips
    fi    
    
}

cpus_gpus()
{
    if [ "$CLOUD" == "gcp" ] ; then
	CPUS=$(gcloud compute instances list | awk '{ print $1 }' | grep "^${PREFIX}" | grep -e "cpu[1-99]" | wc -l)
	GPUS=$(gcloud compute instances list | awk '{ print $1 }' | grep "^${PREFIX}" | grep -e "gpu[1-99]" | wc -l)	
    elif [ "$CLOUD" == "azure" ] ; then
	echo ""
    elif [ "$CLOUD" == "aws" ] ; then
	echo ""	
    fi
}


clear_known_hosts()
{
    echo "ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $host_ip"
    ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $host_ip
    if [ $? -ne 0 ] ; then
	echo ""	
	echo "WARN: Could not clean up known_hosts file"
	echo ""
    fi
}    

enter_email()
{
    if [ "$email" == "" ] ; then
	printf "Please enter your email address to continue: "
	read email

	if [[ $email =~ .*@.* ]]
	then
	    echo "Registering...."
	    echo "{\"id\": \"$rand\", \"name\":\"$email\"}" > .details
	else
	    echo "Exiting. Invalid email address."
	    exit 1
	fi

	curl -H "Content-type:application/json" --data @.details http://snurran.sics.se:8443/keyword --connect-timeout 10 > /dev/null 2>&1
	clear_screen
    fi
}

enter_cloud()
{
    if [ "$CLOUD" == "" ] ; then
        echo "-------------------- Where are you installing Hopsworks? --------------------"
	echo ""
        echo "On what platform are you installing Hopsworks?"
	echo ""
	echo "(1) On-premises or private cloud."
	echo ""
	echo "(2) AWS."
	echo ""
	echo "(3) GCP."
	echo ""
	echo "(4) Azure."
	echo ""
	printf 'Please enter your choice '1', '2', '3', '4' :  '
        read ACCEPT
        case $ACCEPT in
          1)
	    CLOUD="on-premises"
            ;;
          2)
	    CLOUD="aws"
            ;;
          3)
   	    CLOUD="gcp"
            ;;
          4)
       	    CLOUD="azure"
            ;;
          *)
            echo ""
            echo "Invalid Choice: $ACCEPT"
            echo "Please enter your choice '1', '2', '3', '4'."
	    clear_screen
            enter_cloud
            ;;
        esac
	clear_screen
   fi
}


enter_prefix()
{
    if [ "$PREFIX" == "" ] ; then
	echo ""
	printf "The VM names will be prefixed with the string you enter here. Enter the prefix (default: $USER): "
	read PREFIX

	if [ "$PREFIX" == "" ] ; then
            PREFIX=$USER
	fi

	echo "VM name prefix: $PREFIX"

	clear_screen
    fi
}

download_installer() {

    wget -q -nc ${HOPSWORKS_INSTALLER_BRANCH}/hopsworks-installer.sh 2>&1 > /dev/null
    if [ $? -ne 0 ] ; then
	echo "Could not download hopsworks-installer.sh"
	echo "WARNING: There could be a problem with your proxy server settings."	  
        echo "You need to export either the http_proxy or https_proxy enviornment variables."
	echo "Current settings:"
	echo "http_proxy=$http_proxy"
	echo "https_proxy=$https_proxy"
	echo "PROXY=$PROXY"
	exit 3
    fi
    chmod +x hopsworks-installer.sh

    if [ ! -d cluster-defns ] ; then
	mkdir cluster-defns
    fi
    cd cluster-defns
    # Don't overwrite the YML files, so that users can customize them
    wget -q -nc ${CLUSTER_DEFINITION_BRANCH}/$INPUT_YML 2>&1 > /dev/null
    wget -q -nc ${CLUSTER_DEFINITION_BRANCH}/$WORKER_YML 2>&1 > /dev/null
    wget -q -nc ${CLUSTER_DEFINITION_BRANCH}/$WORKER_GPU_YML 2>&1 > /dev/null
    cd ..
}




add_worker()
{
    WORKER_GPUS=$1
    
    if [ "$WORKER_GPUS" -gt "0" ] ; then
	set_name "gpu${GPU_WORKER_ID}"
        create_vm_gpu "worker"
        GPU_WORKER_ID=$((GPU_WORKER_ID+1))	
    else
	set_name "cpu${CPU_WORKER_ID}"	
	create_vm_cpu "worker"
        CPU_WORKER_ID=$((CPU_WORKER_ID+1))		
    fi
}


cpu_worker_size()
{
   if [ "$NUM_WORKERS_CPU" == "" ] ; then
       printf 'Please enter the number of CPU-only workers you want to add (default: 0): '
       read NUM_WORKERS_CPU
       if [ "$NUM_WORKERS_CPU" == "" ] ; then
	   NUM_WORKERS_CPU=0
       fi
   fi
   i=0
   while [ $i -lt $NUM_WORKERS_CPU ] ;
   do
       echo "Adding CPU worker ${i}"
       echo ""
      add_worker 0
      i=$((i+1))
   done
}


gpu_worker_size()
{
   if [ "$NUM_WORKERS_GPU" == "" ] ; then    
     printf 'Please enter the number of GPU-enabled workers you want to add (default: 0): '
     read NUM_WORKERS_GPU
     if [ "$NUM_WORKERS_GPU" == "" ] ; then
       NUM_WORKERS_GPU=0
     fi
   fi
   if [ $NUM_WORKERS_GPU -ne 0 ] ; then
       select_gpu "worker"
   fi
   i=0
   while [ $i -lt $NUM_WORKERS_GPU ] ;
   do
       echo "Adding GPU worker $i"
       echo ""       
      add_worker $NUM_GPUS_PER_VM 
      i=$((i+1))
   done
}


select_gpu()
{
   printf "Please enter the number of GPUs for the $1 VM(s) (default: 0): "
   read NUM_GPUS_PER_VM
   if [ "$NUM_GPUS_PER_VM" == "" ] ; then
       NUM_GPUS_PER_VM=0
   else
     echo ""
     echo "Available GPU types: v100, p100, t4, k80"
     printf 'Please enter the type of GPU: '
     read GPU_TYPE
     case $GPU_TYPE in
         v100 | p100 | k80 | t4)
	  echo ""
	  echo "Number of GPUs per GPU-enabled VM: $NUM_GPUS_PER_VM  GPU type: $GPU_TYPE"
        ;;
        *)
          echo "Invalid GPU choice. Try again."
          echo ""
          select_gpu $1
        ;;
     esac
   fi
}



enter_enterprise_credentials()
{
    if [ -e env.sh ] ; then
	. env.sh	
	echo "Found env.sh for enterprise binaries"
    fi    

    if [ "$ENTERPRISE_DOWNLOAD_URL" == "" ] ; then
        echo ""
        printf "Enter the URL for downloading the Enterprise binaries: "
        read ENTERPRISE_DOWNLOAD_URL
        if [ "$ENTERPRISE_DOWNLOAD_URL" == "" ] ; then
	    echo "Enterprise URL cannot be empty"
	    echo "Exiting."
	    exit 30
	fi
	# Escape URL
	ENTERPRISE_DOWNLOAD_URL=${ENTERPRISE_DOWNLOAD_URL//\./\\\.}
	ENTERPRISE_DOWNLOAD_URL=${ENTERPRISE_DOWNLOAD_URL//\//\\\/}
    fi
    if [ "$ENTERPRISE_USERNAME" == "" ] ; then    
        echo ""
        printf "Enter the username for downloading the Enterprise binaries: "
        read ENTERPRISE_USERNAME
        if [ "$ENTERPRISE_USERNAME" == "" ] ; then
	    echo "Enterprise username cannot be empty"
	    echo "Exiting."
	    exit 32
	fi
    fi
    if [ "$ENTERPRISE_PASSWORD" == "" ] ; then    
        echo ""
        printf "Enter the password for the user ($ENTERPRISE_USERNAME): "
        read -s ENTERPRISE_PASSWORD
	echo ""
        if [ "$ENTERPRISE_PASSWORD" == "" ] ; then
	    echo "The password cannot be empty"
	    echo "Exiting."
	    exit 3
	fi
    fi
}

set_name()
{
    #  NAME="${PREFIX}$1${REGION/-/}"
    NAME="${PREFIX}$1"
}

_check_deletion()
{
    if [ $? -ne 0 ] ; then
	echo "Problem deleting instance: $NAME"
    fi
}


###################################################################
#  GCLOUD VM OPERATIONS                                           #
###################################################################

gcloud_get_ips()
{
    MY_IPS=$(gcloud compute instances list | grep "$PREFIX")

    set_name "head"
    if [ $INSTALL_ACTION -eq $INSTALL_CPU ] ; then
       set_name "cpu"
    elif [ $INSTALL_ACTION -eq $INSTALL_GPU ] ; then
       set_name "gpu"
    fi
    
    IP=$(echo $MY_IPS | sed -e "s/.*${NAME}/${NAME}/" | sed -e "s/RUNNING.*//"| awk '{ print $5 }')

    cpus_gpus
    
    for i in $(seq 1 ${CPUS}) ;
    do
	set_name "cpu${i}"
	CPU[$i]=$(echo $MY_IPS | sed -e "s/.*${NAME}/${NAME}/" | sed -e "s/RUNNING.*//"| awk '{ print $5 }')
	PRIVATE_CPU[$i]=$(echo $MY_IPS | sed -e "s/.*${NAME}/${NAME}/" | sed -e "s/RUNNING.*//" | awk '{ print $4 }')
        echo -e "${NAME}\t Public IP: ${CPU[${i}]} \t Private IP: ${PRIVATE_CPU[${i}]}"
    done

    for j in $(seq 1 ${GPUS}) ;
    do
	set_name "gpu${i}"
	GPU[$j]=$(echo $MY_IPS | sed -e "s/.*${NAME}/${NAME}/" | sed -e "s/RUNNING.*//"| awk '{ print $5 }')
	PRIVATE_GPU[$j]=$(echo $MY_IPS | sed -e "s/.*${NAME}/${NAME}/" | sed -e "s/RUNNING.*//" | awk '{ print $4 }')
        echo -e "${NAME}\t Public IP: ${GPU[${j}]} \t Private IP: ${PRIVATE_GPU[${j}]}"
    done
}    


check_gcp_tools()
{    
    which gcloud > /dev/null
    if [ $? -ne 0 ] ; then
	echo "gcloud does not appear to be installed"
	printf 'Do you want to install gcloud tools? Enter: 'yes' or 'no' (default: yes): '
	read INSTALL_GCLOUD
	if [ "$INSTALL_GCLOUD" == "yes" ] || [ "$INSTALL_GCLOUD" == "" ] ; then
            echo "Installing google-cloud-sdk"
	else
	    echo "Exiting...."
	    exit 44
	fi

	if [ "$DISTRO" == "Ubuntu" ] ; then
          echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
          sudo apt-get install apt-transport-https ca-certificates gnupg
          curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
          sudo apt-get update -y && sudo apt-get install google-cloud-sdk
	elif [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "os" ] ; then
          sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
	  yum install google-cloud-sdk -y
        fi
      gcloud init
    fi
}

gcloud_set_env()
{
    PROJECT=$(gcloud config get-value core/project 2> /dev/null)
    REGION=$(gcloud config get-value compute/region 2> /dev/null)
    ZONE=$(gcloud config get-value compute/zone 2> /dev/null)        
}

gcloud_enter_region()
{
    if [ $NON_INTERACT -eq 0 ] ; then
	gcloud config get-value compute/region
	echo ""
	printf "Do you want to use the current active region (y/n)? (default: y) "
	read KEEP_REGION

	if [ "$KEEP_REGION" == "" ] || [ "$KEEP_REGION" == "y" ] ; then
	    echo ""
	else
	    gcloud compute regions list | awk '{ print $1 }'
	    echo ""
	    printf "Enter the REGION: "
	    read KEEP_REGION
	    gcloud config set compute/region $KEEP_REGION  > /dev/null 2>&1
	fi
    fi
    REGION=$(gcloud config get-value compute/region 2> /dev/null)    
    echo "Active region is: $REGION"

}

gcloud_enter_zone()
{
    if [ $NON_INTERACT -eq 0 ] ; then
	gcloud config get-value compute/zone
	echo ""
	printf "Do you want to use the current active zone (y/n)? (default: y) "
	read KEEP_ZONE

	if [ "$KEEP_ZONE" == "" ] || [ "$KEEP_ZONE" == "y" ] ; then
	    echo ""
	else
	    gcloud compute zones list | grep $REGION  | awk '{ print $1 }'
	    echo ""
	    printf "Enter the ZONE: "
	    read KEEP_ZONE
	    gcloud config set compute/zone $KEEP_ZONE > /dev/null 2>&1
	fi
    fi
    ZONE=$(gcloud config get-value compute/zone 2> /dev/null)    
    echo "Active zone is: $ZONE"
}


gcloud_enter_project()
{
    if [ $NON_INTERACT -eq 0 ] ; then    
	gcloud config get-value project
	echo ""
	printf "Do you want to use the current active project (y/n)? (default: y) "
	read KEEP_PROJECT

	if [ "$KEEP_PROJECT" == "" ] || [ "$KEEP_PROJECT" == "y" ] ; then
	    echo ""
	else
	    gcloud projects list --sort-by=projectId
	    echo ""
	    printf "Enter the PROJECT_ID: "
	    read KEEP_PROJECT
	    gcloud config set core/project $KEEP_PROJECT > /dev/null 2>&1
	fi
    fi
    PROJECT=$(gcloud config get-value core/project 2> /dev/null)
    echo "Active project is: $PROJECT"

}

gcloud_setup()
{
    if [ $NON_INTERACT -eq 0 ] ; then
	check_gcp_tools
    fi
    
    TAGS=http-server,https-server,karamel
    SUBNET=default
    NETWORK_TIER=PREMIUM
    MAINTENANCE_POLICY=TERMINATE
    SERVICE_ACCOUNT=--no-service-account
    BOOT_DISK=pd-ssd
    RESERVATION_AFFINITY=any
    #SHIELD="--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring"
    SHIELD=""

    GCP_USER=$USER

    gcloud_enter_project
    if [ $NON_INTERACT -eq 0 ] ; then
       clear_screen
    fi
    
    gcloud_enter_region
    if [ $NON_INTERACT -eq 0 ] ; then
       clear_screen
    fi

    gcloud_enter_zone    
    
    if [ $NON_INTERACT -eq 0 ] ; then
      clear_screen
    fi

    if [ $NON_INTERACT -eq 0 ] ; then    
	printf "Select IMAGE/IMAGE_PROJECT (centos/ubuntu/custom)? (default: centos) "
	read SELECT_IMAGE

	if [ "$SELECT_IMAGE" == "" ] || [ "$SELECT_IMAGE" == "centos" ] ; then
	    IMAGE=centos-7-v20200714
	    IMAGE_PROJECT=centos-cloud
	elif [ "$SELECT_IMAGE" == "ubuntu" ] ; then
	    IMAGE=ubuntu-1804-bionic-v20200716
	    IMAGE_PROJECT=ubuntu-os-cloud
	else
	    echo "Examples of IMAGE are:"
	    echo "IMAGE=centos-7-v20200714"
	    echo "IMAGE=ubuntu-1804-bionic-v20200716"
	    echo ""
	    printf "Enter the IMAGE: "
	    read IMAGE
	    echo "Examples of IMAGE/IMAGE_PROJECT are:"
	    echo "IMAGE_PROJECT=centoos-cloud"
	    echo "IMAGE_PROJECT=ubuntu-os-cloud"
	    printf "Enter the IMAGE_PROJECT: "
	    read IMAGE_PROJECT
	fi
	echo
	echo "Active IMAGE is: $IMAGE"
	echo "Active IMAGE_PROJECT is: $IMAGE_PROJECT"
	echo ""    
	clear_screen
    fi
}

gcloud_list_public_ips()
{    
    gcloud compute instances list 
}


_gcloud_precreate()
{
    VM_IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')
    if [ "$VM_IP" != "" ] ; then
	echo ""
	echo "WARNING:"	
	echo "VM already exists with name: $NAME"
	echo ""	
    fi
    if [ $NON_INTERACT -eq 0 ] ; then    
	echo ""
	echo "For the $1 VM:"
	echo "Image type: $MACHINE_TYPE"
	printf "Is the default image type OK (y/n)? (default: y) "
	read KEEP_IMAGE
	if [ "$KEEP_IMAGE" == "y" ] || [ "$KEEP_IMAGE" == "" ] ; then
	    echo ""
	else
	    echo ""
	    echo "Example image types: n1-standard-8, n1-standard-16, n1-standard-32"
	    printf "Enter the image type: "
	    read MACHINE_TYPE
	fi
	echo "Image type selected: $MACHINE_TYPE"

	echo ""
	echo "Boot disk size: $BOOT_SIZE_GBS"
	printf "Is the default boot disk size (GBs) OK (y/n)? (default: y) "
	read KEEP_SIZE
	if [ "$KEEP_SIZE" == "y" ] || [ "$KEEP_SIZE" == "" ] ; then
	    echo ""
	else
	    echo ""
	    printf "Enter the boot disk size in GBs: "
	    read BOOT_SIZE_GBS
	fi

	echo ""
	printf "How many NVMe local disks do you want to add to this host (max: 24)? (default: 0) "
	read NUM_NVME_DRIVES_PER_WORKER

	if [ "$NUM_NVME_DRIVES_PER_WORKER" == "" ] ; then
	  NUM_NVME_DRIVES_PER_WORKER=0
	fi
	LOCAL_DISK=
        for (( i=1; i<=${NUM_NVME_DRIVES_PER_WORKER}; i++ ))
	do
	  LOCAL_DISK="$LOCAL_DISK --local-ssd=interface=NVME"
	done
	gcloud_enter_zone	
    fi
    BOOT_SIZE="${BOOT_SIZE_GBS}GB"
    echo "Boot disk size: $BOOT_SIZE"
    
}

gcloud_create_gpu()
{
    GCP_GPU_TYPE=nvidia-tesla-${GPU_TYPE}
    ACCELERATOR="--accelerator=type=${GCP_GPU_TYPE},count=${NUM_GPUS_PER_VM} "    
    _gcloud_create_vm $1
}

gcloud_create_cpu()
{
    ACCELERATOR=""    
    _gcloud_create_vm $1 
}


_gcloud_create_vm()
{
    _gcloud_precreate $1
echo "    gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=$SUBNET --network-tier=$NETWORK_TIER --maintenance-policy=$MAINTENANCE_POLICY $SERVICE_ACCOUNT --no-scopes $ACCELERATOR --tags=$TAGS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=$BOOT_DISK $LOCAL_DISK --boot-disk-device-name=$NAME --reservation-affinity=$RESERVATION_AFFINITY --metadata=ssh-keys=\"$ESCAPED_SSH_KEY\""
    
    gcloud compute --project=$PROJECT instances create $NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --subnet=$SUBNET --network-tier=$NETWORK_TIER --maintenance-policy=$MAINTENANCE_POLICY $SERVICE_ACCOUNT --no-scopes $ACCELERATOR --tags=$TAGS --image=$IMAGE --image-project=$IMAGE_PROJECT --boot-disk-size=$BOOT_SIZE --boot-disk-type=$BOOT_DISK $LOCAL_DISK --boot-disk-device-name=$NAME --reservation-affinity=$RESERVATION_AFFINITY --metadata=ssh-keys="$ESCAPED_SSH_KEY"
    if [ $? -ne 0 ] ; then
      echo "Problem creating VM. Exiting ..."
      exit 12
    fi
    sleep 4
}

gcloud_delete_vm()
{
    nohup gcloud compute instances delete -q $VM_DELETE > gcp-installer.log 2>&1  & 
    RES=$?
    echo "Deleting in the background. Check gcp-installer.log for status."
    exit $RES
}

###################################################################
#  AZURE VM OPERATIONS                                            #
###################################################################

az_get_ips()
{
    echo "Azure get_ips"

    set_name "head"
    if [ $INSTALL_ACTION -eq $INSTALL_CPU ] ; then
       set_name "cpu"
    elif [ $INSTALL_ACTION -eq $INSTALL_GPU ] ; then
       set_name "gpu"
    fi
    # 
    IP=$(az vm list-ip-addresses -g $RESOURCE_GROUP -o table  | grep ^$NAME | awk '{ print $2 }')
    echo -e "${NAME}\t Public IP: $IP"

    cpus_gpus
    
    for i in $(seq 1 ${CPUS}) ;
    do
	set_name "cpu${i}"
	MY_IPS=$(az vm list-ip-addresses -g $RESOURCE_GROUP -o table  | grep ^$NAME | awk '{ print $2, $3 }')
	CPU[$i]=$(echo "$MY_IPS" | awk '{ print $1 }')
	PRIVATE_CPU[$i]=$(echo "$MY_IPS" | awk '{ print $2 }')
        echo -e "${NAME}\t Public IP: ${CPU[${i}]} \t Private IP: ${PRIVATE_CPU[${i}]}"
    done

    for j in $(seq 1 ${GPUS}) ;
    do
        set_name "gpu${i}"
	MY_IPS=$(az vm list-ip-addresses -g $RESOURCE_GROUP -o table  | grep ^$NAME | awk '{ print $2, $3 }')
	GPU[$j]=$(echo "$MY_IPS" | awk '{ print $1 }')
	PRIVATE_GPU[$j]=$(echo "$MY_IPS" | awk '{ print $2 }')
        echo -e "${NAME}\t Public IP: ${GPU[${j}]} \t Private IP: ${PRIVATE_GPU[${j}]}"
    done
}    




_az_set_subscription()
{
    SUBSCRIPTION=$(az account list -o table | grep True | sed -e 's/\s*AzureCloud.*//')
}

_az_enter_subscription()
{
    _az_set_subscription
    if [ $NON_INTERACT -eq 0 ] ; then    
	echo ""
	printf "Do you want to use the current subscription $SUBSCRIPTION (y/n) (default: y)? "
	read KEEP_SUBSCRIPTION

	if [ "$KEEP_SUBSCRIPTION" == "y" ] || [ "$KEEP_SUBSCRIPTION" == "" ] ; then
	    echo ""
	else
            az account list -o table
	    echo ""
	    printf "Enter the Subscription: "
	    read SUBSCRIPTION
	    az account set --subscription "$SUBSCRIPTION"
	    if [ $? -ne 0 ] ; then
		echo "Invalid subscription name: $SUBSCRIPTION"
		echo "Enter a valid subscription name."
		echo ""
		_az_enter_subscription
		return
	    fi
	fi
    fi
    echo "Subscription is: $SUBSCRIPTION"
}

_az_set_location()
{
    REGION=$(az configure -o table -l | tail -n +3 | tail -n +1 | grep ^location | awk '{ print $3 }')
}

_az_enter_location()
{
    _az_set_location
    if [ $NON_INTERACT -eq 0 ] ; then    
	CHANGE=0
	if [ "$REGION" != "" ] ; then
 	  echo ""
  	  printf "Do you want to keep the current Location $REGION (y/n) (default: y)? "
 	  read KEEP_LOCATION
	  if [ "$KEEP_LOCATION" == "n" ] || [ "$KEEP_LOCATION" == "no" ] ; then
	      CHANGE=1
	  fi
        else
	    CHANGE=1
	fi
	if [ $CHANGE -eq 1 ] ; then
            az account list-locations -o table | sed -e 's/.*[0-9]*\.[0-9]*.*[0-9]*\.[0-9]*\s*//' | tail -n +3 | tail -n +1
	    echo ""
	    printf "Enter the Location: "
	    read REGION
	    az configure --defaults location=$REGION
	    if [ $? -ne 0 ] ; then
		echo "Invalid location name: $REGION"
		echo ""	
		_az_enter_location
                return		
	    fi
	fi
    fi
    echo "Location is: $REGION"
}    


_az_set_resource_group()
{
    RESOURCE_GROUP=$(az configure -o table -l | tail -n +3 | tail -n +1 | grep ^group | awk '{ print $3 }')
}

_az_enter_resource_group()
{
    _az_set_resource_group
    if [ $NON_INTERACT -eq 0 ] ; then    
	echo ""
	CHANGE=0
	if [ "$RESOURCE_GROUP" != "" ] ; then
  	    printf "Do you want to keep the Resource Group $RESOURCE_GROUP (y/n) (default: y)? "
	    read KEEP_GROUP
            if [ "$KEEP_GROUP" == "n" ] || [ "$KEEP_GROUP" == "no" ] ; then
		CHANGE=1
	    fi
        else
	    CHANGE=1
	fi
	if [ $CHANGE -eq 1 ] ; then
	    az group list
	    echo ""
	    printf "Enter the Resource Group: "
	    read RESOURCE_GROUP

	    az group exists $RESOURCE_GROUP
	    if [ $? -ne 0 ] ; then
		echo "Creating ResourceGroup: $RESOURCE_GROUP in $RESOURCE_GROUP"
		az group create --name $RESOURCE_GROUP --location $REGION
		if [ $? -ne 0 ] ; then
		    echo "Problem creating resource group: $RESOURCE_GROUP"
		    echo "Exiting..."
		    exit 12
		fi

		
		az configure --defaults group=$RESOURCE_GROUP
		if [ $? -ne 0 ] ; then
		    echo "Invalid resource group: $RESOURCE_GROUP"
		    echo "Enter a valid resource group name."
		    echo ""	
		    _az_enter_resource_group
          	    return		    
		fi
	    fi
	fi
    fi
    echo "Resource Group is: $RESOURCE_GROUP"
}    


_az_set_virtual_network()
{
#    VIRTUAL_NETWORK=$(az network vnet list -g $RESOURCE_GROUP | grep "^    \"name\":" | awk '{ print $2 }' | sed -s 's/\"//g' | sed -e 's/,//')
    VIRTUAL_NETWORK=$(az network vnet list -g $RESOURCE_GROUP -o table | tail -n +3 | awk '{ print $1 }' | tail -1)
}

_az_enter_virtual_network()
{
    _az_set_virtual_network
    if [ $NON_INTERACT -eq 0 ] ; then    
	echo ""
	CHANGE=0
	
	if [ "$VIRTUAL_NETWORK" != "" ] ; then
  	    printf "Do you want to keep the virtual network $VIRTUAL_NETWORK (y/n) (default: y)? "
	    read KEEP_GROUP
            if [ "$KEEP_GROUP" == "n" ] || [ "$KEEP_GROUP" == "no" ] ; then
		CHANGE=1
	    fi
        else
	    CHANGE=1
	fi
	if [ $CHANGE -eq 1 ] ; then
            az network vnet list -g $RESOURCE_GROUP -o table | tail -n +3 | awk '{ print $1 }'	    
	    echo ""
	    printf "Enter the Virtual Network: "
	    read VIRTUAL_NETWORK

	    az network vnet show -n $VIRTUAL_NETWORK 2>&1 > /dev/null
	    if [ $? -ne 0 ] ; then
		echo "Creating ResourceGroup: $VIRTUAL_NETWORK in $VIRTUAL_NETWORK"
                az network vnet create -g $RESOURCE_GROUP -n $VIRTUAL_NETWORK --address-prefixes $ADDRESS_PREFIXES --subnet-name $SUBNET \
		   --subnet-prefixes $SUBNET_PREFIXES --location $REGION		
		if [ $? -ne 0 ] ; then
		    echo "Problem creating resource group: $VIRTUAL_NETWORK"
		    echo "Exiting..."
		    exit 22
		fi

		
		az configure --defaults group=$VIRTUAL_NETWORK
		if [ $? -ne 0 ] ; then
		    echo "Invalid resource group: $VIRTUAL_NETWORK"
		    echo "Enter a valid resource group name."
		    echo ""	
		    _az_enter_resource_group
          	    return		    
		fi
	    fi
	fi
    fi
    echo "Virtual network is: $VIRTUAL_NETWORK"
}    


_az_set_private_dns_zone()
{
    DNS_PRIVATE_ZONE=$(az network private-dns zone list -g $RESOURCE_GROUP |  grep "$RESOURCE_GROUP" | awk '{ print $1 }')
    if [ "$DNS_PRIVATE_ZONE" == "" ] ; then
	DNS_VN_LINK=""
    else
	DNS_VN_LINK=$(az network private-dns link vnet list -g $RESOURCE_GROUP -z $DNS_PRIVATE_ZONE |  grep "$RESOURCE_GROUP" | awk '{ print $1 }')
    fi
}

_az_enter_private_dns_zone()
{
    _az_set_private_dns_zone
    if [ $NON_INTERACT -eq 0 ] ; then    
	echo ""
	DNS_CHANGE=0
	if [ "$DNS_PRIVATE_ZONE" != "" ] ; then
  	    printf "Do you want to keep the DNS private zone ${DNS_PRIVATE_ZONE} (y/n) (default: y)? "
	    read CHANGE
            if [ "$CHANGE" == "n" ] || [ "$CHANGE" == "no" ] ; then
		DNS_CHANGE=1
	    fi
        else
	    DNS_CHANGE=1
	fi

	
	if [ $DNS_CHANGE -eq 1 ] ; then
	    az network private-dns zone list -g $RESOURCE_GROUP
	    echo ""
	    printf "Enter the name for the private DNS Zone (if it does not exist, it will be created): "
	    read DNS_PRIVATE_ZONE
	fi
	if [ "$DNS_PRIVATE_ZONE" == "" ] ; then
	    echo "Error: Private DNS Zone cannot be empty"
	    _az_enter_private_dns_zone
	    return	    
	fi

	az network private-dns zone show -g $RESOURCE_GROUP -n $DNS_PRIVATE_ZONE 2>&1 > /dev/null
	
	if [ $? -ne 0 ] ; then
	    echo ""
	    echo "Could not find DNS private zone, creating...."
	    az network private-dns zone create -g $RESOURCE_GROUP -n $DNS_PRIVATE_ZONE  --location $REGION
	    if [ $? -ne 0 ] ; then
		echo "Problem creating the DNS private zone: $DNS_PRIVATE_ZONE"
		echo "Exiting..."
		exit 33
	    fi
	fi

	
	LINK_CHANGE=0
	if [ "$DNS_VN_LINK" != "" ] ; then
  	    printf "Do you want to keep the DNS virtual network link ${DNS_VN_LINK} (${DNS_PRIVATE_ZONE} to ${VIRTUAL_NETWORK})) (y/n) (default: y)?"
	    read KEEP_LINK
            if [ "$KEEP_LINK" == "n" ] || [ "$KEEP_LINK" == "no" ] ; then
		LINK_CHANGE=1
	    fi
        else
	    LINK_CHANGE=1
	fi

	if [ $LINK_CHANGE -eq 1 ] ; then
	    echo ""
	    printf "Enter the name for the private DNS Zone to Virtual Network link: "
	    read DNS_VN_LINK
	fi
	if [ "$DNS_VN_LINK" == "" ] ; then
	    echo "Error: Private DNS Zone virtual Network link cannot be empty"
	    _az_enter_private_dns_zone
	    return
	fi

	az network private-dns link vnet show -n $DNS_VN_LINK -g $RESOURCE_GROUP -z $DNS_PRIVATE_ZONE 2>&1 > /dev/null
	if [ $? -ne 0 ] ; then
	    echo ""
	    echo "Could not find DNS private zone Virtual Network Link, creating...."
	    az network private-dns link vnet create -g $RESOURCE_GROUP -n $DNS_VN_LINK -z $DNS_PRIVATE_ZONE -v $VIRTUAL_NETWORK -e true
	    if [ $? -ne 0 ] ; then
		echo "Problem creating the DNS private zone - virtual network link: $DNS_VN_LINK"
		echo "Exiting..."
		exit 44
            fi
        fi
	
    fi
    echo "Private DNS Zone and VN Link are: ${DNS_PRIVATE_ZONE}/${DNS_VN_LINK}"
}    



az_setup()
{
    which az 2>&1 > /dev/null
    if [ $? -ne 0 ] ; then

	echo "Azure CLI tools does not appear to be installed"
	printf 'Do you want to install Azure CLI tools?  (y/n) (default: y): '
	read 
	if [ "$INSTALL_AZ" == "y" ] || [ "$INSTALL_AZ" == "" ] ; then
            echo "Installing Azure CLI tools"
	else
	    echo "Exiting...."
	    exit 45
	fi

	if [ "$DISTRO" == "Ubuntu" ] ; then
	    sudo apt-get update -y
	    sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y
	    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
	    AZ_REPO=$(lsb_release -cs)
	    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
	    sudo apt-get update -y
	    sudo apt-get install azure-cli -y
	elif [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "os" ] ; then
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	    sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
	    sudo yum install azure-cli -y
        fi

	az login -o table
	if [ $? -ne 0 ] ; then
	    echo "Problem logging in to Azure"
	    echo "Exiting..."
	    exit 88
	fi

    fi

    _az_enter_subscription
    if [ $NON_INTERACT -eq 0 ] ; then
       clear_screen
    fi
    _az_enter_location
    if [ $NON_INTERACT -eq 0 ] ; then
       clear_screen
    fi
    _az_enter_resource_group
    if [ $NON_INTERACT -eq 0 ] ; then
       clear_screen
    fi
    _az_enter_virtual_network
    if [ $NON_INTERACT -eq 0 ] ; then
       clear_screen
    fi
    _az_enter_private_dns_zone
    if [ $NON_INTERACT -eq 0 ] ; then
       clear_screen
    fi

}


az_list_public_ips()
{
  _az_set_resource_group    
  az vm list-ip-addresses -g $RESOURCE_GROUP --output table #--show-details 
}

_az_precreate()
{
    az vm list-ip-addresses -g $RESOURCE_GROUP -n $NAME 2>&1 > /dev/null
    if [ $? -ne 0 ] ; then
	echo ""
	echo "WARNING:"	
	echo "VM already exists with name: $NAME"
	echo ""
	exit 12
    fi

    if [ $NON_INTERACT -eq 0 ] ; then    
	
	echo ""
	echo "For the $1 VM:"
	echo "VM type (size): $VM_SIZE"
	printf "Is the default VM type OK (y/n)? (default: y) "
	read KEEP_IMAGE
	if [ "$KEEP_IMAGE" == "y" ] || [ "$KEEP_IMAGE" == "" ] ; then
	    echo ""
	else
	    echo ""
	    echo "Example image types: Standard_E4as_v4, Standard_NV6_Promo, etc"
	    printf "Enter the VM type: "
	    read VM_SIZE
	fi
	echo "VM type selected: $VM_SIZE"

	
	echo ""
	echo "For the $1 VM:"
	echo "OS Image: $OS_IMAGE"
	printf "Is the default image type OK (y/n)? (default: y) "
	read KEEP_IMAGE
	if [ "$KEEP_IMAGE" == "n" ] || [ "$KEEP_IMAGE" == "no" ] ; then
	    echo ""
	    echo "Example OS image types: UbuntuLTS, CentoS"
	    printf "Enter the OS image type: "
	    read OS_IMAGE
	fi
	echo "OS Image selected: $OS_IMAGE"
	# az vm image list --all | grep $OS_IMAGE
	# if [ $? -ne 0 ] ; then
	# 	echo "Could not find $OS_IMAGE amoung available images (az vm image list --all)"
	# 	echo "Try again."
	# 	_az_precreate
	# 	return
	# fi
	
	echo ""
	echo "Boot disk size: $BOOT_SIZE_GBS"
	printf "Is the default boot disk size (GBs) OK (y/n)? (default: y) "
	read KEEP_SIZE
	if [ "$KEEP_SIZE" == "y" ] || [ "$KEEP_SIZE" == "" ] ; then
	    echo ""
	else
	    echo ""
	    printf "Enter the boot disk size in GBs: "
	    read BOOT_SIZE_GBS
	fi
	echo "Boot disk size: ${BOOT_SIZE_GBS}GB"
	
	echo ""
	echo "Data disk size: $DATA_DISK_SIZES_GB"
	printf "Is the additional data disk size (GBs) OK (y/n)? (default: y) "
	read KEEP_SIZE
	if [ "$KEEP_SIZE" == "y" ] || [ "$KEEP_SIZE" == "" ] ; then
	    echo ""
	else
	    echo ""
	    printf "Enter the data disk size in GBs: "
	    read DATA_DISK_SIZES_GB
	fi
	DATA_DISK_SIZE=$DATA_DISK_SIZES_GB
	echo "Boot disk size: ${DATA_DISK_SIZE}GB"
    fi
    BOOT_SIZE=$BOOT_SIZE_GBS
}

az_create_gpu()
{
    if [ "$GPU_TYPE" == "k80" ] ; then
	ACCELERATOR_ZONE=3
    elif [ "$GPU_TYPE" == "p100" ] ; then
	ACCELERATOR_ZONE=2	
    elif [ "$GPU_TYPE" == "v100" ] ; then
	ACCELERATOR_ZONE=1	
    else
	ACCELERATOR_ZONE=3	
    fi
    VM_SIZE=$ACCELERATOR_VM
    ACCELERATOR="--size $NUM_GPUS_PER_VM"
    _az_create_vm $1
}

az_create_cpu()
{
    ACCELERATOR=""
    _az_create_vm $1
}

_az_create_vm()
{
    _az_precreate $1
  echo "
  az vm create -n $NAME -g $RESOURCE_GROUP \
   --attach-data-disks \
   --image $OS_IMAGE --data-disk-sizes-gb $DATA_DISK_SIZE --os-disk-size-gb $BOOT_SIZE \
   --generate-ssh-keys --vnet-name $VIRTUAL_NETWORK --subnet $SUBNET \
   --size $VM_SIZE --location $REGION --zone $AZ_ZONE $ACCELERATOR $AZ_NETWORKING\
   --ssh-key-value /home/$USER/.ssh/id_rsa.pub    
"
  az vm create -n $NAME -g $RESOURCE_GROUP \
   --image $OS_IMAGE --data-disk-sizes-gb $DATA_DISK_SIZE --os-disk-size-gb $BOOT_SIZE \
   --generate-ssh-keys --vnet-name $VIRTUAL_NETWORK --subnet $SUBNET \
   --size $VM_SIZE --location $REGION --zone $AZ_ZONE $ACCELERATOR \
   --ssh-key-value /home/$USER/.ssh/id_rsa.pub    
  #   --priority $PRIORITY --max-price 0.06 \
  if [ $? -ne 0 ] ; then
    echo "Problem creating VM. Exiting ..."
    exit 12
  fi
  sleep 20
  # Shortcut to create a network security group (NSG) add the 443 inbound rule, and applies it to the VM 
  az vm open-port -g $RESOURCE_GROUP -n $NAME --port 443
}


az_delete_vm()
{
    _az_set_resource_group
    # _az_set_location

    # if [ "$RM_TYPE" == "cluster" ] ; then
    # 	set_name "head"
    # 	echo "az vm delete -g $RESOURCE_GROUP -n $NAME --yes --no-wait"
    # 	az vm delete -g $RESOURCE_GROUP -n $NAME --yes --no-wait
    #     _check_deletion
	
    # 	cpus_gpus

    # 	for i in $(seq 1 ${CPUS}) ;
    # 	do
    # 	    set_name "cpu${i}"
    #         az vm delete -g $RESOURCE_GROUP -n $NAME --yes --no-wait
    #        _check_deletion	    
    # 	done
	
    # 	for j in $(seq 1 ${GPUS}) ;
    # 	do
    # 	    set_name "gpu${i}"
    #         az vm delete -g $RESOURCE_GROUP --name $NAME --yes --no-wait
    #        _check_deletion	    
    # 	done
    # else
    # 	set_name "$RM_TYPE"
    # 	echo "az vm delete -g $RESOURCE_GROUP --name $NAME --yes --no-wait"
    # 	az vm delete -g $RESOURCE_GROUP --name $NAME --yes --no-wait
    #     _check_deletion
    # fi

    # echo "Deleting VM(s) in the background."

    az vm delete -g $RESOURCE_GROUP --name $VM_DELETE --yes --no-wait
    
}


###################################################################
#  AWS VM OPERATIONS                                              #
###################################################################

check_aws_tools()
{
    which aws 2>&1 > /dev/null
    if [ $? -ne 0 ] ; then
	echo "AWS CLI does not appear to be installed"
	printf "Do you want to install AWS CLI? Enter: 'y/n' (default: y): "
	read INSTALL_AWS
	if [ "$INSTALL_AWS" == "y" ] || [ "$INSTALL_AWS" == "" ] ; then
            echo "Installing AWS CLI"
	else
	    echo "Exiting...."
	    exit 77
	fi

	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
	aws --version
	if [ $? -ne 0 ] ; then
	    echo "Problem installing aws tools"
	    echo "Exiting..."
	    exit 88
	fi
        aws configure
    fi
}

aws_setup()
{
    if [ $NON_INTERACT -eq 0 ] ; then
	check_aws_tools
    fi
}

aws_list_public_ips()
{
    # aws ec2    --output table
  echo ""
}

_aws_precreate()
{
    echo ""
}

aws_create_gpu()
{
    echo ""    
}

aws_create_cpu()
{
  echo ""    
}

_aws_create_vm()
{
    _az_precreate $1        
}


aws_delete_vm()
{
  echo ""
}


###################################################################
#  ABSTRACT VM OPERATIONS                                              #
###################################################################

_missing_cloud()
{
    echo "You forgot to specify your cloud provider. "
    echo "Add the switch '-c gcp' for GCP, '-c aws' for AWS, '-c azure' for Azure."
    echo ""
    exit 42    
}    

create_vm_cpu()
{
    
    echo "Creating VM...."
    echo ""
    if [ "$CLOUD" == "gcp" ] ; then
      gcloud_create_cpu $1
    elif [ "$CLOUD" == "azure" ] ; then
      az_create_cpu $1
    elif [ "$CLOUD" == "aws" ] ; then
      aws_create_cpu $1
    else
      _missing_cloud	
    fi
}

create_vm_gpu()
{
    echo "Creating gpu-enabled VM...."
    echo ""
    if [ "$CLOUD" == "gcp" ] ; then
      gcloud_create_gpu $1
    elif [ "$CLOUD" == "azure" ] ; then
      az_create_gpu $1
    elif [ "$CLOUD" == "aws" ] ; then
      aws_create_gpu $1
    else
      _missing_cloud	
    fi
    echo ""
    echo "To check the VM status, run:"
    echo "./hopsworks-cloud-installer.sh -l -c gcp|azure|aws"
    echo ""
}


delete_vm()
{
    #enter_prefix
    if [ "$VM_DELETE" == "" ] ; then
        list_public_ips	
	echo ""
	printf "Enter the name of the VM to delete: "
	read VM_DELETE
    fi

    echo "Deleting $VM_DELETE"
    if [ "$CLOUD" == "gcp" ] ; then
      gcloud_delete_vm
    elif [ "$CLOUD" == "azure" ] ; then
      az_delete_vm
    elif [ "$CLOUD" == "aws" ] ; then
      aws_delete_vm
    else
      _missing_cloud	
    fi
    echo ""
    echo "To check the VM status, run:"
    echo "./hopsworks-cloud-installer.sh -l -c gcp|azure|aws"
    echo ""
    
}

list_public_ips()
{
    echo "Listing public IPs"
    echo ""
    if [ "$CLOUD" == "gcp" ] ; then
      gcloud_list_public_ips
    elif [ "$CLOUD" == "azure" ] ; then
      az_list_public_ips
    elif [ "$CLOUD" == "aws" ] ; then
	aws_list_public_ips
    else
      _missing_cloud	
    fi    
}

cloud_setup()
{

    RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
    ESCAPED_SSH_KEY="$RAW_SSH_KEY"
    
    if [ "$CLOUD" == "gcp" ] ; then
      gcloud_setup
    elif [ "$CLOUD" == "azure" ] ; then
      az_setup
    elif [ "$CLOUD" == "aws" ] ; then
      aws_setup
    else
      _missing_cloud	
    fi    
}    

###################################################################
#   MAIN                                                          #
###################################################################
help()
{
              echo "usage: $SCRIPTNAME "
	      echo " [-h|--help]      help message"
	      echo " [-i|--install-action community|community-gpu|community-cluster|enterprise|kubernetes]"
	      echo "                 'community' installs Hopsworks Community on a single VM"
	      echo "                 'community-gpu' installs Hopsworks Community on a single VM with GPU(s)"
	      echo "                 'community-cluster' installs Hopsworks Community on a multi-VM cluster"
	      echo "                 'enterprise' installs Hopsworks Enterprise (single VM or multi-VM)"
	      echo "                 'kubernetes' installs Hopsworks Enterprise (single VM or multi-VM) alson with open-source Kubernetes"
	      echo " [-c|--cloud gcp|aws|azure] Name of the public cloud "
	      echo " [-dr|--dry-run]  generates cluster definition (YML) files, allowing customization of clusters."
	      echo " [-drc|--dry-run-create-vms]  creates the VMs, generates cluster definition (YML) files but doesn't run karamel."	      	      
	      echo " [-g|--num-gpu-workers num] Number of workers (with GPUs) to create for the cluster."
	      echo " [-gpus|--num-gpus-per-worker num] Number of GPUs per worker."
	      echo " [-gt|--gpu-type type]"
	      echo "                 'v100' Nvidia Tesla V100"
	      echo "                 'p100' Nvidia Tesla P100"
	      echo "                 't4' Nvidia Tesla T4"	      
	      echo "                 'k80' Nvidia K80"	      
	      echo " [-d|--download-enterprise-url url] downloads enterprise binaries from this URL."
	      echo " [-dc|--download-url url] downloads binaries from this URL."
	      echo " [-du|--download-user username] Username for downloading enterprise binaries."
	      echo " [-dp|--download-password password] Password for downloading enterprise binaries."
	      echo " [-l|--list-public-ips] List the public ips of all VMs."
	      echo " [-n|--vm-name-prefix name] The prefix for the VM name created."
	      echo " [-ni|--non-interactive] skip license/terms acceptance and all confirmation screens."
	      echo " [-nvme|--nvme num_disks] the number of disks to attach to each worker node"	      
	      echo " [-rm|--remove] Delete a VM - you will be prompted for the name of the VM to delete."
	      echo " [-sc|--skip-create] skip creating the VMs, use the existing VM(s) with the same vm_name(s)."
	      echo " [-w|--num-cpu-workers num] Number of workers (CPU only) to create for the cluster."	      
	      echo ""
	      exit 3

}


while [ $# -gt 0 ]; do    # Until you run out of parameters . . .
  case "$1" in
      -h|--help|-help)
	      help
	      ;;
    -i|--install-action)
	      shift
	      case $1 in
		 community)
		      INSTALL_ACTION=$INSTALL_CPU
		      ACTION="localhost-tls"
  		      ;;
		 community-gpu)
                      INSTALL_ACTION=$INSTALL_GPU
		      ACTION="localhost-tls"		     
  		      ;;
		 community-cluster)
                      INSTALL_ACTION=$INSTALL_CLUSTER
		      ENTERPRISE=0
		      ACTION="cluster"
		      ;;
		 enterprise)
		      INSTALL_ACTION=$INSTALL_CLUSTER
                      ENTERPRISE=1
		      ACTION="enterprise"		      
		      ;;
		 kubernetes)
		      INSTALL_ACTION=$INSTALL_CLUSTER
                      ENTERPRISE=1
                      KUBERNETES=1
		      ACTION="kubernetes"		      
		      ;;
		  *)
		      echo "Could not recognise '-i' option: $1"
              	      get_install_option_help		      
		 esac
	       ;;
    -c|--cloud)
	      shift
	      case $1 in
		 gcp|aws|azure)
		      CLOUD=$1
  		      ;;
		 *)
                     echo "Invalid option for '-c' option: $1"
		     echo "Valid options are: gcp | azure | aws"
                     exit 44
		 esac
	       ;;
    -d|--download-enterprise-url)
      	      shift
	      ENTERPRISE_DOWNLOAD_URL=$1
	      ;;
    -dc|--download-url)
      	      shift
	      DOWNLOAD_URL=$1
	      ;;
    -du|--download-username)
      	      shift
	      ENTERPRISE_USERNAME=$1
	      ;;
    -dp|--download-password)
      	      shift
	      ENTERPRISE_PASSWORD=$1
	      ;;
    -dr|--dry-run)
              DRY_RUN=1
              ;;
    -drc|--dry-run-create-vms)
              DRY_RUN_CREATE_VMS=1
              ;;
    -g|--num-gpu-workers)
              shift
	      NUM_WORKERS_GPU=$1
              ;;
    -gpus|--num-gpus-per-host)
      	      shift
              NUM_GPUS_PER_VM=$1
	      ;;
    -gt|--gpu-type)
      	      shift
	      case $1 in
		 v100 | p100 | k80)
		      GPU_TYPE=$1
  		      ;;
		  *)
		      echo "Could not recognise option: $1"
		      exit_error "Failed."
	      esac
	      ;;
    -nvme|--nvme)
	      shift
	      NUM_NVME_DRIVES_PER_WORKER=$1
              for (( i=1; i<=${NUM_NVME_DRIVES_PER_WORKER}; i++ ))
	      do
		  LOCAL_DISK="$LOCAL_DISK --local-ssd=interface=NVME"
	      done
     	      ;;
    -l|--list-public-ips)
	      DO_LISTING=1
	      ;;	
    -ni|--non-interactive)
	      NON_INTERACT=1
	      ;;
    -rm|--remove)
	RM_TYPE="delete"
	#VM_DELETE=$1
	      # case $1 in
	      # 	 cpu | gpu | cluster)
	      # 	      RM_TYPE=$1
  	      # 	      ;;
	      # 	  *)
	      # 	      echo "Could not recognise option: $1"
	      # 	      exit_error "Failed."
	      #esac
	      ;;
    -n|--vm-name-prefix)
      	      shift
	      PREFIX=$1
              ;;
    -sc|--skip-create)
      	      SKIP_CREATE=1
              ;;
    -p|--http-proxy)
              shift
              PROXY=$1
              proto="$(echo $PROXY | grep :// | sed -e's,^\(.*://\).*,\1,g')"
	      if [ "$proto" == "http://" ] ; then
		  export http_proxy=$PROXY
	      elif [ "$proto" == "https://" ] ; then
		  export https_proxy=$PROXY
	      else
		  echo "Invalid proxy URL: $PROXY"
		  echo "URL must start with 'https://'  or 'http://'"
		  exit 20
	      fi	      
	      ;;
    -w|--num-cpu-workers)
              shift
	      NUM_WORKERS_CPU=$1
              ;;
    *)
	  exit_error "Unrecognized parameter: $1"
	  ;;
  esac
  shift       # Check next set of parameters.
done


if [ $DO_LISTING -eq 1 ] ; then
    list_public_ips
    exit 0
fi

if [ "$RM_TYPE" != "" ] ; then
    delete_vm
    exit 0
fi    

if [ $DRY_RUN -eq 1 ] ; then
    NON_INTERACT=1
fi    

if [ $NON_INTERACT -eq 0 ] ; then    
  check_linux
  splash_screen
  display_license
  accept_license
  clear_screen
  enter_email
  enter_cloud
  install_action
  enter_prefix    
fi

if [ "$CLOUD" != "gcp" ] ; then
    if [ $NUM_NVME_DRIVES_PER_WORKER -gt 0 ] ; then
	echo ""
	echo "Sorry! NVM disks are currently only supported for GCP."
	echo ""
        exit 88
    fi
fi


download_installer
if [ $DRY_RUN -eq 1 ] ; then
    echo ""
    echo "The cluster definition (YML) files are now available here:"
    echo "$(pwd)/cluster-defns"
    ls -l $(pwd)/cluster-defns
    echo ""    
    echo "You can customize/edit them and re-run this installer."
    echo ""
    exit 0
fi    
cloud_setup

if [ $INSTALL_ACTION -eq $INSTALL_CPU ] ; then
    set_name "cpu"
elif [ $INSTALL_ACTION -eq $INSTALL_GPU ] ; then
    set_name "gpu"    
    if [ $NON_INTERACT -eq 0 ] ; then        
	select_gpu "head"
    fi
elif [ $INSTALL_ACTION -eq $INSTALL_CLUSTER ] ; then
    set_name "head"    
    if [ $NON_INTERACT -eq 0 ] ; then        
	select_gpu "head"
    fi
else
    exit_error "Bad install action: $INSTALL_ACTION"
fi

if [ $ENTERPRISE -eq 1 ] ; then
    enter_enterprise_credentials
fi    

if [ $SKIP_CREATE -eq 0 ] ; then
    if [ $INSTALL_ACTION -eq $INSTALL_GPU ] ; then    
	create_vm_gpu "head"
    else
	create_vm_cpu "head"
    fi
    if [ $INSTALL_ACTION -eq $INSTALL_CLUSTER ] ; then
        cpu_worker_size
        gpu_worker_size
    fi
else
    echo "Skipping VM creation...."
fi	

if [ $INSTALL_ACTION -eq $INSTALL_CLUSTER ] ; then
    set_name "head"    
fi  

IP=
while [ "$IP" == "" ] ; do
    get_ips
    sleep 5
done


host_ip=$IP
clear_known_hosts

if [[ "$IMAGE" == *"centos"* ]]; then
    ssh -t -o StrictHostKeyChecking=no $IP "sudo yum install wget -y > /dev/null"
fi    


echo "Installing installer on $IP"
scp -o StrictHostKeyChecking=no ./hopsworks-installer.sh ${IP}:
if [ $? -ne 0 ] ; then
    echo "Problem copying installer to head server. Exiting..."
    exit 10
fi    

ssh -t -o StrictHostKeyChecking=no $IP "mkdir -p cluster-defns"
if [ $? -ne 0 ] ; then
    echo "Problem creating 'cluster-defns' directory on head server. Exiting..."
    exit 11
fi    

scp -o StrictHostKeyChecking=no ./cluster-defns/hopsworks-*.yml ${IP}:~/cluster-defns/
if [ $? -ne 0 ] ; then
    echo "Problem scp'ing cluster definitions to head server. Exiting..."
    exit 12
fi    

if [ $INSTALL_ACTION -eq $INSTALL_CLUSTER ] ; then
    
    ssh -t -o StrictHostKeyChecking=no $IP "if [ ! -e /home/$USER/.ssh/id_rsa.pub ] ; then cat /dev/zero | ssh-keygen -q -N \"\" ; fi"
    pubkey=$(ssh -t -o StrictHostKeyChecking=no $IP "cat /home/$USER/.ssh/id_rsa.pub")

    keyfile=".pubkey.pub"
    echo "$pubkey" > $keyfile
    echo ""
    echo "Public key for head node is:"
    echo "$pubkey"
    echo ""


    WORKERS="-w "

    if [ $NUM_WORKERS_CPU -eq 0 ] && [ $NUM_WORKERS_GPU -eq 0 ] ; then
	WORKERS="-w none "
    fi
    
    for i in $(seq 1 ${CPUS}) ;
    do
	host_ip=${CPU[${i}]}
	echo "I think host_ip is ${CPU[$i]}"
	echo "I think host_ip is ${CPU[${i}]}"
	echo "All  hosts ${CPU[*]}"    
	clear_known_hosts

	ssh-copy-id -o StrictHostKeyChecking=no -f -i $keyfile ${CPU[${i}]}
	ssh -t -o StrictHostKeyChecking=no $IP "ssh -t -o StrictHostKeyChecking=no ${PRIVATE_CPU[${i}]} \"pwd\""
	if [ $? -ne 0 ] ; then
	    echo ""
	    echo "Error. Public key SSH from $IP to ${PRIVATE_CPU[${i}]} not working."
	    echo "Exiting..."
	    echo ""
	    exit 9
	else
	    echo "Success: SSH from $IP to ${PRIVATE_CPU[${i}]}"
	fi

	WORKERS="${WORKERS}${PRIVATE_CPU[${i}]},"

	echo "workers: $WORKERS"
    done

    for i in $(seq 1 ${GPUS}) ;
    do
	host_ip=${GPU[${i}]}	
	echo "I think host_ip is ${GPU[$i]}"
	echo "I think host_ip is ${GPU[${i}]}"
	echo "All  hosts ${GPU[*]}"    
	clear_known_hosts
	ssh-copy-id -o StrictHostKeyChecking=no -f -i $keyfile ${GPU[${i}]}
	ssh -t -o StrictHostKeyChecking=no $IP "ssh -t -o StrictHostKeyChecking=no ${PRIVATE_GPU[${i}]} \"pwd\""
	if [ $? -ne 0 ] ; then
	    echo ""
	    echo "Error. Public key SSH from $IP to ${PRIVATE_GPU[${i}]} not working."
	    echo "Exiting..."
	    echo ""
	    exit 9
	else
	    echo "Success: SSH from $IP to ${PRIVATE_GPU[${i}]}"
	fi

	WORKERS="${WORKERS}${PRIVATE_GPU[${i}]},"

	echo "workers: $WORKERS"
    done
    WORKERS=${WORKERS::-1}
else
    WORKERS="-w none"
fi

if [ $ENTERPRISE -eq 1 ] ; then
    DOWNLOAD=""
    if [ "$ENTERPRISE_DOWNLOAD_URL" != "" ] ; then
	DOWNLOAD="-d $ENTERPRISE_DOWNLOAD_URL "
    fi
    if [ "$ENTERPRISE_USERNAME" != "" ] ; then
	DOWNLOAD_USERNAME="-du $ENTERPRISE_USERNAME "
    fi
    if [ "$ENTERPRISE_PASSWORD" != "" ] ; then
	DOWNLOAD_PASSWORD="-dp $ENTERPRISE_PASSWORD "
    fi
fi

echo ""
echo "Running installer on $IP :"
echo ""


DRY_RUN_KARAMEL=""
if [ $DRY_RUN_CREATE_VMS -eq 1 ] ; then
    DRY_RUN_KARAMEL=" -dr "
fi

NVME_SWITCH=""
if [ $NUM_NVME_DRIVES_PER_WORKER -gt 0 ] ; then
    NVME_SWITCH=" -nvme $NUM_NVME_DRIVES_PER_WORKER "
fi
    echo "ssh -t -o StrictHostKeyChecking=no $IP \"/home/$USER/hopsworks-installer.sh -i $ACTION -ni -c $CLOUD ${DOWNLOAD}${DOWNLOAD_USERNAME}${DOWNLOAD_PASSWORD}${WORKERS}${DRY_RUN_KARAMEL}${NVME_SWITCH} && sleep 5\""    
    ssh -t -o StrictHostKeyChecking=no $IP "/home/$USER/hopsworks-installer.sh -i $ACTION -ni -c $CLOUD ${DOWNLOAD}${DOWNLOAD_USERNAME}${DOWNLOAD_PASSWORD}${WORKERS}${DRY_RUN_KARAMEL}${NVME_SWITCH} && sleep 5"

    if [ $? -ne 0 ] ; then
	echo "Problem running installer. Exiting..."
	exit 2
    fi

if [ $DRY_RUN_CREATE_VMS -eq 0 ] ; then    
    echo ""
    echo "****************************************"
    echo "*                                      *"
    echo "* Public IP access to Karamel at:      *"
    echo "  http://${IP}:9090/index.html   "
    echo "*                                      *"
    echo "* Public IP access to Hopsworks at:    *"
    echo "  https://${IP}/hopsworks   "
    echo "*                                      *"
    echo "* View installation progress:          *"
    echo " ssh ${IP} \"tail -f installation.log\"   "
    echo "*                                      *"
    echo "****************************************"
else
    echo ""
    echo "****************************************"
    echo "*                                      *"
    echo "*                                      *"    
    echo " ssh ${IP}"
    echo " Then, edit your cluster definition /home/$USER/cluster-defns/$YML_FILE"
    echo " Then run karamel on your new cluster definition: "
    echo " cd karamel-0.6"
    echo " setsid ./bin/karamel -headless -launch ../$YML_FILE > ../installation.log 2>&1 &"
    echo "*                                      *"    
    echo "****************************************"
fi    

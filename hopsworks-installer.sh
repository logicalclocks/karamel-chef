#!/bin/bash 

###################################################################################################
#                                                                                                 #
# This code is released under the GNU General Public License, Version 3, see for details:         #
# http://www.gnu.org/licenses/gpl-3.0.txt                                                         #
#                                                                                                 #
#                                                                                                 #
# Copyright (c) Logical Clocks AB, 2020.                                                             #
# All Rights Reserved.                                                                            #
#                                                                                                 #
###################################################################################################

###################################################################################################
#                                                                                                 #
#                                                                                                 #
# | |  | |                                  | |                                                   #
# | |__| | ___  _ __  _____      _____  _ __| | _____                                             #
# |  __  |/ _ \| '_ \/ __\ \ /\ / / _ \| '__| |/ / __|                                            #
# | |  | | (_) | |_) \__ \\ V  V / (_) | |  |   <\__ \                                            #
# |_|__|_|\___/| .__/|___/ \_/\_/ \___/|_|  |_|\_\___/                                            #
# |_   _|      | || |      | | |                                                                  #
#   | |  _ __  |_|| |_ __ _| | | ___ _ __                                                         #
#   | | | '_ \/ __| __/ _` | | |/ _ \ '__|                                                        #
#  _| |_| | | \__ \ || (_| | | |  __/ |                                                           #       
# |_____|_| |_|___/\__\__,_|_|_|\___|_|                                                           #
#                                                                                                 #
###################################################################################################

HOPSWORKS_VERSION=1.2.0
HOPSWORKS_BRANCH=1.2
CLUSTER_DEFINITION_BRANCH=karamel_installer
KARAMEL_VERSION=0.6
INSTALL_ACTION=
NON_INTERACT=0
SCRIPTNAME=`basename $0`
AVAILABLE_MEMORY=$(free -g | grep Mem | awk '{ print $2 }')
AVAILABLE_DISK=$(df -h | grep '/$' | awk '{ print $4 }')
AVAILABLE_MNT=$(df -h | grep '/mnt$' | awk '{ print $4 }')
AVAILABLE_CPUS=$(cat /proc/cpuinfo | grep '^processor' | wc -l)
IP=$(hostname -I | awk '{ print $1 }')
HOSTNAME=$(hostname -f)
DISTRO=
WORKER_ID=0
DRY_RUN=0
CLEAN_INSTALL_DIR=0
SUDO_PWD=
INSTALL_LOCALHOST=1
INSTALL_LOCALHOST_TLS=2
INSTALL_CLUSTER=3
INSTALL_KARAMEL=4
INSTALL_NVIDIA=5
PURGE_HOPSWORKS=7
PURGE_HOPSWORKS_ALL_HOSTS=8
TLS="false"
REVERSE_DNS=1

CLOUD=
GCP_NVME=0
RM_CLASS=
ENTERPRISE=0
KUBERNETES=0
DOWNLOAD=
KUBERNETES_RECIPES=
INPUT_YML="cluster-defns/hopsworks-installer.yml"
YML_FILE="cluster-defns/hopsworks-installer-active.yml"
ENTERPRISE_ATTRS=
KUBE="false"

which lspci > /dev/null
if [ $? -ne 0 ] ; then
    # this only happens on centos
   echo "Installing pciutils ...."
   sudo yum install pciutils -y > /dev/null
fi    
AVAILABLE_GPUS=$(sudo lspci | grep -i nvidia | wc -l)


unset_gpus()
{
RM_CLASS="hops:
    yarn:"
}
unset_gpus


set_gpus()
{
RM_CLASS="cuda:
        accept_nvidia_download_terms: true
      hops:
        capacity: 
          resource_calculator_class: org.apache.hadoop.yarn.util.resource.DominantResourceCalculatorGPU
        yarn:
          gpus: '*'"
}

# $1 = String describing error
exit_error() 
{
  #CleanUpTempFiles

  echo "" $ECHO_OUT
  echo "Error number: $1"
  echo "Exiting $PRODUCT $VERSION installer."
  echo ""
  exit 1
}

# $1 = accept phrase (what to accept)
# caller reads $ENTERED_STRING global variable for result
enter_string() 
{
     echo "$1"
     read ENTERED_STRING
}

###################################################################################################
# SCREEN CLEAR FUNCTIONS
###################################################################################################

clear_screen()
{
 if [ $NON_INTERACT -eq 0 ] ; then
   echo ""
   echo "Press ENTER to continue"
   read cont < /dev/tty
 fi 
 clear
}

clear_screen_no_skipline()
{
 if [ $NON_INTERACT -eq 0 ] ; then
    echo "Press ENTER to continue"
    read cont < /dev/tty
 fi 
 clear
}


#######################################################################
# LICENSING
#######################################################################

splash_screen() 
{   
  clear
  echo ""
  echo "Karamel/Hopsworks Installer, Copyright(C) 2020 Logical Clocks AB. All rights reserved."
  echo ""
  echo "This program can install Karamel/Chef and/or Hopsworks."
  echo ""
  echo "To cancel installation at any time, press CONTROL-C" 
  echo ""  
  echo "You appear to have following setup on this host:"
  echo "* available memory: $AVAILABLE_MEMORY"
  echo "* available disk space (on '/' root partition): $AVAILABLE_DISK"
  echo "* available disk space (on '/mnt' partition): $AVAILABLE_MNT"  
  echo "* available CPUs: $AVAILABLE_CPUS"
  echo "* available GPUS: $AVAILABLE_GPUS"  
  echo "* your ip is: $IP"
  echo "* installation user: $USER"
  echo "* linux distro: $DISTRO"

  strlen=${#HOSTNAME}
  if [ $strlen -gt 64 ] ; then
      echo ""
      echo "WARNING: hostname is longer 64 chars which can cause problems with OpenSSL: $HOSTNAME"
      echo ""
  fi

  if [ $AVAILABLE_MEMORY -lt 29 ] ; then
      echo ""
      echo "WARNING: We recommend at least 32GB of RAM. Minimum is 16GB of Ram. You have $AVAILABLE_MEMORY GB of RAM"
      echo ""
  fi

  space=${AVAILABLE_DISK::-1}
  if [ $space -lt 60 ] && [ "$AVAILABLE_MNT" == "" ]; then
      echo ""
      echo "WARNING: We recommend at least 60GB of disk space on the root partition. Minimum is 50GB of available disk."
      echo "You have $AVAILABLE_DISK space on '/', and no space on '/mnt'."
      echo ""
  fi
  if [ "$AVAILABLE_MNT" != "" ] ; then
      mnt=${AVAILABLE_MNT::-1}
      if [ $space -lt 30 ] || [ $mnt < 50 ]; then
      echo ""
      echo "WARNING: We recommend at least 30GB of disk space on the root partition as well as at least 50GB on the /mnt partition."
      echo "You have $AVAILABLE_DISK space on '/', and ${space}G on '/mnt'."
      echo ""
      fi
  fi
  if [ $AVAILABLE_CPUS -lt 4 ] ; then
      echo ""
      echo "WARNING: Hopsworks needs at least 4 CPUs to be able to run Spark applications."
      echo ""
  fi       
  
  which dig > /dev/null
  if [ $? -ne 0 ] ; then
    echo "Installing dig ..."
    if [ "$DISTRO" == "Ubuntu" ] ; then
        sudo apt install dnsutils -y  > /dev/null
    elif [ "$DISTRO" == "centos" ] ; then      
	sudo yum install bind-utils -y > /dev/null
    fi
  fi
  # If there are multiple FQDNs for this IP, return the last one (this works on Azure)
  reverse_hostname=$(dig +noall +answer -x $IP | awk '{ print $5 }' | tail -1)
  # stirp off trailing '.' chracter on the hostname returned
  reverse_hostname=${reverse_hostname::-1}
  if [ "$reverse_hostname" != "$HOSTNAME" ] ; then
      REVERSE_DNS=0
      echo ""
      echo "WARNING: Reverse DNS does not work on this host. If you enable 'TLS', it will not work."
      echo "Hostname: $HOSTNAME"
      echo "Reverse Hostname: $reverse_hostname"
      echo ""
      echo "Azure: if you have already added this VM to a 'Private DNS Zone', then contineu. This script will make reverse-DNS work correctly for local IPs."
      echo "https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal"
      echo ""
      echo "On-premises: you have to configure your networking to make reverse-DNS work correctly."
      echo ""
  fi

  
  pgrep mysql > /dev/null
  if [ $? -eq 0 ] ; then
      echo ""
      echo "WARNING: A MySQL service is already running on this host. This could case installation problems."
      echo -n "A service is running at this pid: "
      pgrep mysql | tail -1
      echo ""
  fi
  pgrep glassfish-domain1 > /dev/null
  if [ $? -eq 0 ] ; then
      echo ""
      echo "WARNING: A Hopsworks server is already running on this host. This could case installation problems."
      echo -n "A service is running at this pid: "
      pgrep glassfish-domain1 | tail -1
      echo ""
  fi
  pgrep airflow > /dev/null
  if [ $? -eq 0 ] ; then
      echo ""
      echo "WARNING: An Airflow server is already running on this host. This could case installation problems."
      echo -n "A service is running at this pid: "
      pgrep airflow | tail -1
      echo ""
  fi
  pgrep hadoop > /dev/null
  if [ $? -eq 0 ] ; then
      echo ""
      echo "WARNING: A Hadoop server is already running on this host. This could case installation problems."
      echo -n "A service is running at this pid: "
      pgrep hadoop | tail -1
      echo ""
  fi
  pgrep ndb > /dev/null
  if [ $? -eq 0 ] ; then
      echo ""
      echo "WARNING: A MySQL Cluster (NDB) instance is already running on this host. This could case installation problems."
      echo -n "A service is running at this pid: "
      pgrep ndb | tail -1
      echo ""
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
  echo "Logical Clocks AB is furnishing this item "as is". Logical Clocks AB does not provide any"
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


get_install_option_help()
{
  if [ $ROOTUSER -eq 1 ] ; then
    INSTALL_AS_DAEMON_HELP="You are installing cluster as root user. Karamel will run as a root process in 'nohup' mode."
  else
    INSTALL_AS_DAEMON_HELP="You are installing cluster as normal (non-root) user. Karamel will run as a user-level process in 'nohup' mode."
  fi

INSTALL_OPTION_HELP="
Install Options Help\n
===========================================================================\n
This program installs Karamel and can also install Hopsworks using Karamel and Chef-Solo.\n
$INSTALL_AS_DAEMON_HELP\n
\n
(1) Setup and start a single-host Hopsworks installation using Karamel. The cluster will run on this machine. \n
    \tThe binaries and directories for storing data will all be under /srv/hops.\n
    \tHopsworks will run at the end of the installation.\n
(2) Setup and start a multi-host Hopsworks installation using Karamel. The cluster will run on all the machines. \n
    \tHopsworks will run at the end of the installation.\n
(3) Setup, install, and run Karamel on this host. \n
    \tKaramel can be used to install Hopsworks by opening the URL in your browser: http://${ip}:9090/index.html \n
"
}

install_action()
{
    if [ "$INSTALL_ACTION" == "" ] ; then

        echo "-------------------- Installation Options --------------------"
	echo ""
        echo "What would you like to do?"
	echo ""
	echo "(1) Install a single-host Hopsworks cluster."
	echo ""
	echo "(2) Install a single-host Hopsworks cluster with TLS enabled."
	echo ""
	echo "(3) Install a multi-host Hopsworks cluster with TLS enabled."
	echo ""
	echo "(4) Install an Enterprise Hopsworks cluster." 
	echo ""
	echo "(5) Install an Enterprise Hopsworks cluster with Kubernetes"
	echo ""
	echo "(6) Install and start Karamel."
	echo ""
	echo "(7) Install Nvidia drivers and reboot server."
	echo ""
	echo "(8) Purge (uninstall) Hopsworks from this host."
	echo ""	
	echo "(9) Purge (uninstall) Hopsworks from ALL hosts."
	echo ""	
	printf 'Please enter your choice '1', '2', '3', '4', '5', '6', '7', '8', '9',  'q' \(quit\), or 'h' \(help\) :  '
        read ACCEPT
        case $ACCEPT in
          1)
	    INSTALL_ACTION=$INSTALL_LOCALHOST
            ;;
          2)
	    INSTALL_ACTION=$INSTALL_LOCALHOST_TLS
	    if [ $REVERSE_DNS -eq 0 ] ; then
		echo ""
		echo "Error: reverse DNS is not working. Cannot install TLS-enabled Hopsworks."
		echo ""
		exit_error 12 
	    fi
            ;;
          3)
	    INSTALL_ACTION=$INSTALL_CLUSTER
            ;;
          4)
            INSTALL_ACTION=$INSTALL_CLUSTER
            ENTERPRISE=1
            ;;
          5)
            INSTALL_ACTION=$INSTALL_CLUSTER
            ENTERPRISE=1
	    KUBERNETES=1
            ;;
          6)
	    INSTALL_ACTION=$INSTALL_KARAMEL
            ;;
          7)
	    INSTALL_ACTION=$INSTALL_NVIDIA
            ;;
          8)
	    INSTALL_ACTION=$PURGE_HOPSWORKS
            ;;
          9)
	    INSTALL_ACTION=$PURGE_HOPSWORKS_ALL_HOSTS
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

enter_email()
{

    echo "Please enter your email address to continue:"
    read email

    if [[ $email =~ .*@.* ]]
    then
	echo "Registering hopsworks instance...."
	echo "{\"id\": \"$rand\", \"name\":\"$email\"}" > .details
    else
	echo "Exiting. Invalid email"
	exit 1
    fi

    curl -H "Content-type:application/json" --data @.details http://snurran.sics.se:8443/keyword
}


add_worker()
{
   printf 'Please enter the IP of the worker you want to add: '
   read WORKER_IP

   ssh -t -o StrictHostKeyChecking=no $WORKER_IP "whoami" > /dev/null
   if [ $? -ne 0 ] ; then
      echo "Failed to ssh using public into: ${USER}@${WORKER_IP}"
      echo "Cannot add worker node, as you need to be able to ssh into it using your public key"
      exit_error
   fi

   WORKER_MEM=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "free -g | grep Mem | awk '{ print \$2 }'")
   WORKER_DISK=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "df -h | grep '/\$' | awk '{ print \$4 }'") 
   WORKER_CPUS=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "cat /proc/cpuinfo | grep '^processor' | wc -l")

   NUM_GBS=$(expr $AVAILABLE_MEMORY - 2)
   NUM_CPUS=$(expr $AVAILABLE_CPUS - 1)
   
   echo "Amount of disk space available on root partition ('/'): $WORKER_DISK"
   echo "Amount of memory available on worker: $WORKER_MEM"
   printf 'Please enter the amout of memory in this worker to be used (GBs)'
   echo -n ". Default is $NUM_GBS: "
   read GBS
   if [ "$GBS" == "" ] ; then
       GBS=$NUM_GBS
   fi
   
   MBS=$(expr $GBS \* 1024)
   echo "Amount of CPUs available on worker: $WORKER_CPUS"
   printf 'Please enter the number of CPUs in this worker to be used'
   echo -n ". Default is $NUM_CPUS: "   
   read CPUS
   if [ "$CPUS" == "" ] ; then
       CPUS=$NUM_CPUS
   fi

   if [ "$DISTRO" == "centos" ] ; then
       ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo yum install pciutils -y"
   fi

   if [ "$CLOUD" == "azure" ] ; then
       echo ""
       echo "On Azure, you need to add every worker to the same Private DNS Zone, and note the hostname you set in Azure."
       printf 'Please enter that private DNS hostname for this worker:'
       read PRIVATE_HOSTNAME
       ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo hostname $PRIVATE_HOSTNAME"
   fi       
   
   WORKER_GPUS=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo lspci | grep -i nvidia | wc -l")
   if [ "$WORKER_GPUS" == "" ] ; then
     WORKER_GPUS=0
   fi
   echo ""
   echo "Number of GPUs found on worker: $WORKER_GPUS"
   echo ""
   if [[ "$WORKER_GPUS" > "0" ]] ; then
       printf 'Do you want all of the GPUs to be used by this worker (y/n (default y):'
       read ACCEPT
       if [ "$ACCEPT" == "y" ] || [ "$ACCEPT" == "yes" ] || [ "$ACCEPT" == "" ] ; then
	   echo "$WORKER_GPUS will be used on this worker."
	   if [ "$DISTRO" == "centos" ] ; then
             echo "Installing kernel-devel on worker.."
	     ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo yum install \"kernel-devel-uname-r == $(uname -r)\" -y" > /dev/null
	   fi
       else
	   echo "$The GPUs will not be used on this worker."
	   WORKER_GPUS=0
       fi
   else
       echo "No worker GPUs available"
   fi

   if [[ "$WORKER_GPUS" > "0" ]] ; then
       set_gpus
   else
       unset_gpus
   fi
echo "  
  datanode${WORKER_ID}:
    size: 1
    baremetal:
      ip: ${WORKER_IP}
    attrs:
      $RM_CLASS
          vcores: $CPUS
          memory_mbs: $MBS
    recipes:
      - kagent
      - conda
      - hops::dn
      - hops::nm
      - hadoop_spark::yarn
      - hadoop_spark::certs
      - flink::yarn
      - hopslog::_filebeat-spark
      - hopslog::_filebeat-kagent
      - hopslog::_filebeat-beam
      - tensorflow
      - hopsmonitor::node_exporter
" >> $YML_FILE

if [ $? -ne 0 ] ; then
 echo ""
 echo "Failure: could not add a worker to the yml file."
 exit_error
fi
WORKER_ID=$((WORKER_ID+1))
}


worker_size()
{
    # Edit this file: /etc/ssd/sshd_config
    
    #chmod 644 ~/.ssh/authorized_keys
    #chmod 700 ~/.ssh
    #RSAAuthentication yes
    #PubkeyAuthentication yes
    #AuthorizedKeysFile    .ssh/authorized_keys
    #PasswordAuthentication no
   printf 'Please enter the number of extra workers you want to add (default: 0): '
   read NUM_WORKERS
   if [ "$NUM_WORKERS" == "" ] ; then
       NUM_WORKERS=0
   fi
   i=0
   while [ $i -lt $NUM_WORKERS ] ;
   do
      add_worker
      i=$((i+1))
      clear_screen      
   done
}


install_dir()
{
   root="${AVAILABLE_DISK//G}"
   mnt="${AVAILABLE_MNT//G}"
   
   if [ "$mnt" != "" ] && [ $mnt -gt $root ] ; then
       sudo mkdir -p /mnt/hops
       sudo rm -rf /srv/hops
       sudo ln -s /mnt/hops /srv/hops
   fi
}




# called if interrupt signal is handled
TrapBreak() 
{
  trap "" HUP INT TERM
  echo -e "\n\nInstallation cancelled by user!"
  exit_error $EXIT_SIGNAL_CAUGHT
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
	fi
    else
        exit_error "This script only works for Linux."	
    fi
}

check_userid()
{
  # Check if user is root
  USERID=`id | sed -e 's/).*//; s/^.*(//;'`
  if [ "X$USERID" == "Xroot" ]; then
    exit_error "This script only works for non-root users."
  fi
}

purge_local()
{
   echo "Shutting down services..."
   if sudo test -f "/srv/hops/kagent/kagent/bin/shutdown-all-local-services.sh"  ; then
     sudo /srv/hops/kagent/kagent/bin/shutdown-all-local-services.sh -f > /dev/null
   fi
   echo "Killing karamel..."
   pkill java
   echo "Removing karamel..."   
   rm -rf ~/karamel*
   echo "Removing cookbooks..."   
   sudo rm -rf ~/.karamel   
   sudo rm -rf /tmp/chef-solo/cookbooks
   echo "Purging old installation..."      
   sudo rm -rf /srv/hops/*   
}

###################################################################################################
###################################################################################################
###################################################################################################
# 
# START OF SCRIPT MAINLINE
# 
###################################################################################################
###################################################################################################
###################################################################################################



while [ $# -gt 0 ]; do    # Until you run out of parameters . . .
  case "$1" in
    -h|--help|-help)
	      echo ""
	      echo "You can install Karamel asa normal user."
              echo "usage: [sudo] ./$SCRIPTNAME "
	      echo " [-h|--help]      help message"
	      echo " [-i|--install-action localhost|cluster|karamel] "
	      echo "                 'localhost' installs a localhost Hopsworks cluster"
	      echo "                 'localhost-tls' installs a localhost Hopsworks cluster with TLS enabled"	      
	      echo "                 'cluster' installs a multi-host Hopsworks cluster"
	      echo "                 'enterprise' installs a multi-host Hopsworks cluster"	      
	      echo "                 'karamel' installs and starts Karamel"
	      echo "                 'purge' removes Hopsworks completely from this host"
	      echo "                 'purge-all' removes Hopsworks completely from ALL hosts"	      
	      echo " [-cl|--clean]    removes the karamel installation"
	      echo " [-dr|--dry-run]      does not run karamel, just generates YML file"
	      echo " [--gcp-nvme]     mount NVMe disk on GCP node"
	      echo " [-c|--cloud     on-premises|gcp|aws|azure]"
	      echo " [-ni|--non-interactive)]"
	      echo "                  skip license/terms acceptance and all confirmation screens."
	      echo "" 
	      exit 3
              break
	      ;;
    -i|--install-action)
	      shift
	      case $1 in
		 localhost)
		      INSTALL_ACTION=$INSTALL_LOCALHOST
  		      ;;
		 localhost-tls)
		      INSTALL_ACTION=$INSTALL_LOCALHOST_TLS
  		      ;;
		 cluster)
		      INSTALL_ACTION=$INSTALL_CLUSTER
		      ;;
		 enterprise)
		      INSTALL_ACTION=$INSTALL_CLUSTER
                      ENTERPRISE=1
		      ;;
		 kubernetes)
		      INSTALL_ACTION=$INSTALL_CLUSTER
                      ENTERPRISE=1
                      KUBERNETES=1		      
		      ;;
	         karamel)
		      INSTALL_ACTION=$INSTALL_KARAMEL
		      ;;
	         nvidia)
		      INSTALL_ACTION=$INSTALL_NVIDIA
		      ;;
	         purge)
		      INSTALL_ACTION=$PURGE_HOPSWORKS
		      ;;
	         purge-all)
		      INSTALL_ACTION=$PURGE_HOPSWORKS_ALL_HOSTS
		      ;;
		  *)
		      echo "Could not recognise option: $1"
		      exit_error "Failed."
		 esac
	       ;;
    -cl|--clean)
	      CLEAN_INSTALL_DIR=1
	      ;;
    -dr|--dry-run)
	      DRY_RUN=1
	      ;;
    -gn|--gcp-nvme)
	      GCP_NVME=1
	      ;;
    -c|--cloud)
	      shift
	      case $1 in
		 on-premises)
		      CLOUD="on-premises"
  		      ;;
		 gcp)
		      CLOUD="gcp"
  		      ;;
		 aws)
		      CLOUD="awsp"
		      ;;
	         azure)
		      CLOUD="azure"
		      ;;
		  *)
		      echo "Could not recognise option: $1"
		      exit_error "Failed."
		 esac
	       ;;
    -ni|--non-interactive)
	      NON_INTERACT=1
	      ;;
    -y|--yml) 
              shift
              yml=$1
              ;;
    -pwd|--password)
	      SUDO_PWD="-passwd $1"
	      ;;
    *)
	  exit_error "Unrecognized parameter: $1"
	  ;;
  esac
  shift       # Check next set of parameters.
done


############################################################################################################
############################################################################################################
#                                                                                                          #
#   MAINLINE: START OF CONTROL FOR PROGRAM: FUNCTIONS CALLED FROM HERE                                     #
#                                                                                                          #
############################################################################################################
############################################################################################################

# Catch signals and clean up temp files
trap TrapBreak HUP INT TERM  

check_linux

check_userid

if [ $NON_INTERACT -eq 0 ] ; then
    splash_screen  
    display_license
    accept_license  
    clear_screen
#    enter_email
#    clear_screen
fi

install_action

if [ "$INSTALL_ACTION" == "$INSTALL_NVIDIA" ] ; then
   sudo -- sh -c 'echo "blacklist nouveau
     options nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf'
   sudo update-initramfs -u
   echo "Rebooting....."
   sudo reboot
fi

if [ "$INSTALL_ACTION" == "$PURGE_HOPSWORKS_ALL_HOSTS" ] ; then   
    IPS=$(grep 'ip:' hopsworks-installer-active.yml | awk '{ print $2 '})
    cd							 
    for ip in $IPS ; do
	echo ""
	echo "Purging on host: $ip"	
	scp hopsworks-installer.sh ${ip}:
	ssh $ip "./hopsworks-installer.sh -i purge -ni"
	ssh $ip "rm -f hopsworks-installer.sh"	
    done

    # Only delete local files after other hosts
    purge_local
    
    echo ""
    echo "*********************************************"
    echo "Finished cleaning all hosts."
    echo "*********************************************"    
    exit 0
fi

if [ "$INSTALL_ACTION" == "$PURGE_HOPSWORKS" ] ; then
   purge_local
   exit 0
fi
									 
# generate a pub/private keypair if none exists
if [ ! -e ~/.ssh/id_rsa.pub ] ; then
  cat /dev/zero | ssh-keygen -q -N "" > /dev/null
else
  echo "Found existing id_rsa.pub"
fi

# Karamel needs to be able to ssh back into the host it is running on to install Hopsworks there
pub=$(cat ~/.ssh/id_rsa.pub)
grep "$pub" ~/.ssh/authorized_keys > /dev/null
if [ $? -ne 0 ] ; then
  echo "Not currently able to ssh into this host. Updating authorized_keys"
  pushd .
  cd ~/.ssh
  cat id_rsa.pub >> authorized_keys 
  if [ $? -ne 0 ] ; then
      echo "Problem updating .ssh/authorized_keys file. Could not add .ssh/id_rsa.pub to authorized_keys file."
  fi
  popd
else
  echo "Found existing entry in authorized_keys"
fi    

ssh -t -o StrictHostKeyChecking=no localhost "whoami" > /dev/null
ssh -t -o StrictHostKeyChecking=no $IP "whoami" > /dev/null
if [ $? -ne 0 ] ; then
    exit_error "Error: problem using ssh to connect to this host with ip: $IP"
fi    

which java > /dev/null
if [ $? -ne 0 ] ; then
    echo "Installing Java..."
    clear_screen
    if [ "$DISTRO" == "Ubuntu" ] ; then
	sudo apt update -y
	sudo apt install openjdk-8-jre-headless -y
    elif [ "$DISTRO" == "centos" ] ; then
	sudo yum install java-1.8.0-openjdk-headless -y
	sudo yum install wget -y 
    else
	echo "Could not recognize Linux distro: $DISTRO"
	exit_error
    fi
fi

if [ $GCP_NVME -eq 1 ] ; then
   sudo mkdir -p /mnt/nvmeDisks/nvme0
   sudo mkfs.ext4 -F /dev/nvme0n1
fi

install_dir

if [ ! -d cluster-defns ] ; then
    mkdir cluster-defns
fi
if [ ! -e $INPUT_YML ] ; then
    cd cluster-defns
    wget https://raw.githubusercontent.com/logicalclocks/karamel-chef/${CLUSTER_DEFINITION_BRANCH}/$INPUT_YML
    cd ..
fi

if [ "$INSTALL_ACTION" == "$INSTALL_CLUSTER" ] || [ "$INSTALL_ACTION" == "$INSTALL_LOCALHOST" ] || [ "$INSTALL_ACTION" == "$INSTALL_LOCALHOST_TLS" ]  ; then
    clear_screen    
    enter_cloud
    cp -f $INPUT_YML $YML_FILE
fi

if [ "$CLOUD" == "azure" ] ; then
    echo ""
    echo "On Azure, you need to add every host in Hopsworks to the same Private DNS Zone, and note the hostname you set in Azure."
    printf 'Please enter the private DNS hostname for this head node:'
    read PRIVATE_HOSTNAME
    sudo hostname $PRIVATE_HOSTNAME
    clear_screen
fi       



if [ ! -d karamel-${KARAMEL_VERSION} ] ; then
    echo "Installing Karamel..."
    clear_screen    
    wget http://www.karamel.io/sites/default/files/downloads/karamel-${KARAMEL_VERSION}.tgz
    if [ $? -ne 0 ] ; then
	exit_error "Problem downloading karamel"
    fi
    tar zxf karamel-${KARAMEL_VERSION}.tgz
    if [ $? -ne 0 ] ; then
	exit_error "Problem extracting karamel from archive"
    fi
else
  echo "Found karamel"
fi

if [ "$INSTALL_ACTION" == "$INSTALL_CLUSTER" ] ; then
  worker_size
fi    

if [ "$INSTALL_ACTION" == "$INSTALL_LOCALHOST_TLS" ] ; then
  TLS="true"
fi

if [ "$INSTALL_ACTION" == "$INSTALL_KARAMEL" ]  ; then
    cd karamel-${KARAMEL_VERSION}
    nohup ./bin/karamel -headless &
    echo "To access Karamel, open your browser at: "
    echo ""
    echo "http://${ip}:9090/index.html"
    echo ""    
else
    sudo -n true
    if [ $? -ne 0 ] ; then
	echo ""
	echo "It appears you need a sudo password for this account."
        echo -n "Enter the sudo password for $USER: "
	read -s passwd
        SUDO_PWD="-passwd $passwd"
	echo ""
    fi

    if [ $AVAILABLE_GPUS -gt 0 ] ; then
      RM_CLASS="cuda:
    accept_nvidia_download_terms: true
  hops:nnn
    capacity: 
      resource_calculator_class: org.apache.hadoop.yarn.util.resource.DominantResourceCalculatorGPU
    yarn:
      gpus: '*'"
    else
      unset_gpus	
    fi    


    DNS_IP=$(sudo cat /etc/resolv.conf | grep ^nameserver | awk '{ print $2 }' | tail -1)
    BASE_PWD=$(date | md5sum | head -c${1:-8})
    GBS=$(expr $AVAILABLE_MEMORY - 2)
    MEM=$(expr $GBS \* 1024)    
    perl -pi -e "s/__CLOUD__/$CLOUD/" $YML_FILE
    perl -pi -e "s/__MEM__/$MEM/" $YML_FILE
    perl -pi -e "s/__PWD__/$BASE_PWD/g" $YML_FILE
    perl -pi -e "s/__DNS_IP__/$DNS_IP/g" $YML_FILE        
    CPUS=$(expr $AVAILABLE_CPUS - 1)
    perl -pi -e "s/__CPUS__/$CPUS/" $YML_FILE
    perl -pi -e "s/__VERSION__/$HOPSWORKS_VERSION/" $YML_FILE
    perl -pi -e "s/__BRANCH__/$HOPSWORKS_BRANCH/" $YML_FILE    
    perl -pi -e "s/__USER__/$USER/" $YML_FILE
    perl -pi -e "s/__IP__/$IP/" $YML_FILE
    perl -pi -e "s/__RM_CLASS__/$RM_CLASS/" $YML_FILE
    perl -pi -e "s/__TLS__/$TLS/" $YML_FILE
    if [ $ENTERPRISE -eq 1 ] ; then
	echo ""
        echo -n "Enter the URL to download the Enterprise Binaries from: "
	read DOWNLOAD_URL
	DOWNLOAD_URL=${DOWNLOAD_URL//\./\\\.}
	DOWNLOAD_URL=${DOWNLOAD_URL//\//\\\/}	
        echo ""	
	#DNS_IP=$(printf "%q" "$DNS_IP")
	DNS_IP=${DNS_IP//\./\\\.}
	if [ $KUBERNETES -eq 1 ] ; then
	  KUBE="true"
          DOWNLOAD="download_url: $DOWNLOAD_URL
  kube-hops:
    pki:
     verify_hopsworks_cert: false
    fallback_dns: $DNS_IP
"
          KUBERNETES_RECIPES="- kube-hops::hopsworks
      - kube-hops::ca
      - kube-hops::master
      - kube-hops::post_conf
      - kube-hops::addons
      - kube-hops::node
"	  
	else
          DOWNLOAD="download_url: $DOWNLOAD_URL"	    
	fi
        ENTERPRISE_ATTRS="enterprise:
      install: true
      download_url: $DOWNLOAD_URL"

    fi
    perl -pi -e "s/__ENTERPRISE__/$ENTERPRISE_ATTRS/" $YML_FILE
    perl -pi -e "s/__DOWNLOAD__/$DOWNLOAD/" $YML_FILE
    perl -pi -e "s/__KUBERNETES_RECIPES__/$KUBERNETES_RECIPES/" $YML_FILE
    perl -pi -e "s/__KUBE__/$KUBE/" $YML_FILE
    
  if [ $DRY_RUN -eq 0 ] ; then
    cd karamel-${KARAMEL_VERSION}
    echo "Running command from ${PWD}:"
    echo "   nohup ./bin/karamel -headless -launch ../$YML_FILE $SUDO_PWD > ../installation.log &"
    nohup ./bin/karamel -headless -launch ../$YML_FILE $SUDO_PWD > ../installation.log &
    echo ""
    echo "********************************************************************************************"
    echo ""
    echo "In a couple of mins, you can open your browser to check your installation: http://${IP}:9090/index.html"
    echo ""
    echo "Note: port 9090 must be open on your host for external traffic if you want to use your browser."
    echo ""
    echo "You can also view the logs with this command:"
    echo ""
    echo "tail -f installation.log"
    echo ""    
    cd ..
  fi
fi

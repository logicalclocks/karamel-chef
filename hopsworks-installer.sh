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

HOPSWORKS_REPO=logicalclocks/hopsworks-chef
HOPSWORKS_BRANCH=master
CLUSTER_DEFINITION_BRANCH=https://raw.githubusercontent.com/logicalclocks/karamel-chef/$HOPSWORKS_BRANCH
KARAMEL_VERSION=0.6
INSTALL_ACTION=
NON_INTERACT=0
SCRIPTNAME=`basename $0`
AVAILABLE_MEMORY=$(free -g | grep Mem | awk '{ print $2 }')
AVAILABLE_DISK=$(df -h | grep '/$' | awk '{ print $4 }')
AVAILABLE_DISK=${AVAILABLE_DISK%.*}
# Azure mounts /mnt/resource - AWS/GCP mount /mnt
AVAILABLE_MNT=$(df -h | grep '/mnt' | awk '{ print $4 }')
AVAILABLE_MNT=${AVAILABLE_MNT%.*}
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
#GCP_NVME=0
#NUM_GCP_NVME_DRIVES_PER_WORKER=0

YARN="yarn:
      cgroups_strict_resource_usage: 'false'"
RM_WORKER=
ENTERPRISE=0
KUBERNETES=0
DOWNLOAD=
KUBERNETES_RECIPES=""
INPUT_YML="cluster-defns/hopsworks-head.yml"
WORKER_YML="cluster-defns/hopsworks-worker.yml"
WORKER_GPU_YML="cluster-defns/hopsworks-worker-gpu.yml"
YML_FILE="cluster-defns/hopsworks-installation.yml"
ENTERPRISE_ATTRS=
KUBE="false"
WORKER_LIST=
WORKER_IP=
WORKER_DEFAULTS=
HAS_GPUS=0
AVAILABLE_GPUS=
CUDA=

KARAMEL_HTTP_PROXY_1=
KARAMEL_HTTP_PROXY_2=
KARAMEL_HTTP_PROXY_3=
PROXY=

# $1 = String describing error
exit_error()
{
  #CleanUpTempFiles

  echo "" $ECHO_OUT
  echo "Error number: $1"
  echo "Exiting hopsworks-installer.sh."
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
  echo "* available disk space (under '/mnt' partition): $AVAILABLE_MNT"
  echo "* available CPUs: $AVAILABLE_CPUS"
  echo "* available GPUS: $AVAILABLE_GPUS"
  echo "* your ip is: $IP"
  echo "* installation user: $USER"
  echo "* linux distro: $DISTRO"
  echo "* cluster defn branch: $CLUSTER_DEFINITION_BRANCH"
  echo "* hopsworks-chef branch: $HOPSWORKS_REPO/$HOPSWORKS_BRANCH"

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

  if [[ "$AVAILABLE_DISK" == *"G"* ]]; then
      space=${AVAILABLE_DISK::-1}
  else
      space=${AVAILABLE_DISK}
  fi
  if [ $space -lt 60 ] && [ "$AVAILABLE_MNT" == "" ]; then
      echo ""
      echo "WARNING: We recommend at least 60GB of disk space on the root partition. Minimum is 50GB of available disk."
      echo "You have $AVAILABLE_DISK space on '/', and no space on '/mnt'."
      echo ""
  fi
  if [ "$AVAILABLE_MNT" != "" ] ; then
      if [[ "$AVAILABLE_MNT" == *"G"* ]]; then
	  mnt=${AVAILABLE_MNT::-1}
      else
	  mnt=${AVAILABLE_MNT}
      fi

      if [ $space -lt 30 ] || [ $mnt < 50 ]; then
      echo ""
      echo "WARNING: We recommend at least 30GB of disk space on the root partition as well as at least 50GB on the /mnt partition."
      echo "You have ${space}G space on '/', and ${mnt}G on '/mnt'."
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
    elif [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "os" ] ; then
	sudo yum install bind-utils -y > /dev/null
    fi
  fi
  # If there are multiple FQDNs for this IP, return the last one (this works on Azure)
  reverse_hostname=$(dig +noall +answer -x $IP | awk '{ print $5 }' | sort -r |  grep -v 'internal.cloudapp.net')
  # stirp off trailing '.' chracter on the hostname returned
  reverse_hostname=${reverse_hostname::-1}
  if [ "$reverse_hostname" != "$HOSTNAME" ] ; then
      REVERSE_DNS=0
      echo ""
      echo "WARNING: Reverse DNS does not work on this host. If you enable 'TLS', it will not work."
      echo "Hostname: $HOSTNAME"
      echo "Reverse Hostname: $reverse_hostname"
      echo "Azure Installatione: please continue, we will try and fix this during the installation."
#      echo "https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal"
#      echo ""
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


get_install_option_help()
{

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


#
# To test http_proxy support:
# yum install iptables-services
# netstat -plant
# Reference: https://www.thegeekstuff.com/scripts/iptables-rules
#
# Delete all existing rules:
# iptables -F
#
# Allow incoming ssh (and connection response)
# sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# sudo iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEP
# iptables -A OUTPUT -o eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
#
# allow related traiff
# sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
# sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# sudo iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT


# drop other incoming Traffic:
# iptables -A INPUT -j DROP
#
# Allow outgoing ssh connections:
# iptables -A OUTPUT -o eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -A INPUT -i eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
#
# Allow outgoing https:
# iptables -A OUTPUT -o eth0 -p tcp -d 192.168.100.0/24 --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -A INPUT -i eth0 -p tcp -d 192.168.100.0/24 --sport 443 -m state --state ESTABLISHED -j ACCEPT
#
# Allow loopback
# iptables -A INPUT -i lo -j ACCEPT
# iptables -A OUTPUT -o lo -j ACCEPT

set_karamel_http_proxy()
{

    # extract the protocol
    proto="$(echo $PROXY | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    # remove the protocol
    url="$(echo ${PROXY/$proto/})"
    # extract the user (if any)
    user="$(echo $url | grep @ | cut -d@ -f1)"
    # extract the host and port
    hostport="$(echo ${url/$user@/} | cut -d/ -f1)"
    # by request host without port
    host="$(echo $hostport | sed -e 's,:.*,,g')"
    # by request - try to extract the port
    port="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    if [ "$port" == "" ] ; then
	if [ "$proto" == "http://" ] ; then
	    port="80"
	elif [ "$proto" == "https://" ] ; then
	    port="443"
	else
	    port=-1
	fi
    fi
    if [ "$proto" == "http://" ] ; then
        KARAMEL_HTTP_PROXY_1="export http_proxy=${proto}${host}:${port}"
        KARAMEL_HTTP_PROXY_2="export http_proxy_host=$host"
        KARAMEL_HTTP_PROXY_3="export http_proxy_port=$port"		
    elif [ "$proto" == "https://" ] ; then
        KARAMEL_HTTP_PROXY_1="export https_proxy=${proto}${host}:${port}"
        KARAMEL_HTTP_PROXY_2="export https_proxy_host=$host"
        KARAMEL_HTTP_PROXY_3="export https_proxy_port=$port"		
	
    else
	echo "Error. Unrecognized http(s) proxy protocol: $proto is a problem from $PROXY"
	exit 15
    fi

    if [ $NON_INTERACT -eq 0 ] ; then

      if [ "$proto" == "http://" ] ; then
  	export http_proxy="${proto}${host}:${port}"	    
      elif [ "$proto" == "https://" ] ; then
  	export https_proxy="${proto}${host}:${port}"	    	  
      fi
      rm -f index.html	
      wget http://www.logicalclocks.com/index.html 2>&1 > /dev/null
      if [ $? -ne 0 ] ; then
	  echo "WARNING: There could be a problem with the proxy server setting."	  
          echo "WARNING: wget (with http proxy 'on') could not download this file: http://www.logicalclocks.com/index.html"
	  echo "http_proxy=$http_proxy"
	  echo "https_proxy=$https_proxy"
	  echo "PROXY=$PROXY"	  
      fi
      rm -f index.html
    fi
}    


check_proxy()
{
   echo ""
   printf "Is the host running this installer behind a http proxy (y/n)? "
   read ACCEPT
   case $ACCEPT in
       y|yes)
	   # Just take the first http proxy set - https or http, not both https_proxy and http_proxy
           printf "Enter the URL of the HTTP(S) PROXY: "
           read PROXY
           set_karamel_http_proxy
	   
	   echo "Your HTTP(S) Proxy host/port is: host: $host and port: $port"
           printf "Does that look ok (y/n)? (default: 'y') "
           read OK
           case $OK in
               y|yes)
		 ;;
              *)
               clear_screen
               check_proxy
           esac
	   ;;
       n|no)
           ;;
       *)
           echo ""
           echo "Invalid Choice: $ACCEPT"
           echo "Please enter your choice 'y' or 'yes' for yes, 'n' or 'no' for no: "
	   clear_screen
           check_proxy
           ;;
   esac
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
	echo "Registering...."
	echo "{\"id\": \"$rand\", \"name\":\"$email\"}" > .details
    else
	echo "Exiting. Invalid email address."
	exit 1
    fi

    curl -H "Content-type:application/json" --data @.details http://snurran.sics.se:8443/keyword --connect-timeout 10 > /dev/null 2>&1
}

update_worker_yml()
{
  perl -pi -e "s/__WORKER_ID__/$WORKER_ID/" $tmpYml
  perl -pi -e "s/__WORKER_IP__/$WORKER_IP/" $tmpYml
  perl -pi -e "s/__MBS__/$MBS/" $tmpYml
  perl -pi -e "s/__CPUS__/$CPUS/" $tmpYml
  cat $tmpYml >> $YML_FILE
}

add_worker()
{
    if [ "$WORKER_DEFAULTS" != "true" ] ; then
	printf 'Please enter the IP of the worker you want to add: '
	read WORKER_IP
    fi

    ssh -t -o StrictHostKeyChecking=no $WORKER_IP "whoami" > /dev/null
    if [ $? -ne 0 ] ; then
	echo "Failed to ssh using public into: ${USER}@${WORKER_IP}"
	echo "Cannot add worker node, as you need to be able to ssh into it using your public key"
	echo ""
	echo ""
	echo "You can setup passwordless SSH to setup to ${USER}@${WORKER_IP} by entering the password."
	echo "Running ssh-copy-id.... "
	ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub ${USER}@${WORKER_IP}
	if [ $? -ne 0 ] ; then
            exit_error "Problem setting up passwordless SSH to ${USER}@${WORKER_IP}"
	fi
    fi

    WORKER_MEM=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "free -m | grep Mem | awk '{ print \$2 }'")
    WORKER_DISK=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "df -h | grep '/\$' | awk '{ print \$4 }'")
    WORKER_CPUS=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "cat /proc/cpuinfo | grep '^processor' | wc -l")

    NUM_GBS=$(expr $WORKER_MEM - 2)
    NUM_CPUS=$(expr $WORKER_CPUS - 1)

    MBS=$WORKER_MEM

    echo "Amount of disk space available on root partition ('/'): $WORKER_DISK"
    echo "Amount of memory available on this worker: $WORKER_MEM MBs"
    if [ "$WORKER_DEFAULTS" != "true" ] ; then
	printf "Please enter the amout of memory in this worker to be used (GBs): "
	read GBS
	MBS=$(expr $GBS \* 1024)
    fi

    echo "Amount of CPUs available on worker: $WORKER_CPUS"

    CPUS=$WORKER_CPUS
    if [ "$WORKER_DEFAULTS" != "true" ] ; then
	printf "Please enter the number of CPUs in this worker to be used: "
	read CPUS
    fi

    if [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "os" ] ; then
	ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo yum install pciutils -y"
    fi

    WORKER_MNT=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo df -h | grep '/mnt' | awk '{ print $4 }'")

    re='^[0-9]+$'

    if [ "$CLOUD" == "azure" ] ; then
	NSLOOKUP=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "nslookup $WORKER_IP | grep name | grep -v 'internal.cloudapp.net'")
	SUSPECTED_HOSTNAME=$(echo $NSLOOKUP | awk {' print $4 '})
	SUSPECTED_HOSTNAME=${SUSPECTED_HOSTNAME::-1}
	echo ""
	echo "On Azure, you need to add every worker to the same Private DNS Zone, and note the hostname you set in Azure."
	echo "We suspect the private DNS hostname is:"
	echo "    $SUSPECTED_HOSTNAME"
	echo ""
	if [ "$WORKER_DEFAULTS" != "true" ] ; then
	    printf  "Please enter the private DNS hostname for this worker (default: $SUSPECTED_HOSTNAME): "
	    read PRIVATE_HOSTNAME
	    if [ "$PRIVATE_HOSTNAME" == "" ] ; then
		PRIVATE_HOSTNAME=$SUSPECTED_HOSTNAME
	    fi
	else
	    PRIVATE_HOSTNAME=$SUSPECTED_HOSTNAME
	fi
	ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo hostname $PRIVATE_HOSTNAME"


	if [[ $WORKER_MNT =~ $re ]] ; then
            ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo rm -rf /srv/hops; sudo mkdir -p /mnt/resource/hops; sudo ln -s /mnt/resource/hops /srv/hops"
	fi
    else
	if [[ $WORKER_MNT =~ $re ]] ; then
            ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo rm -rf /srv/hops; sudo mkdir -p /mnt/hops; sudo ln -s /mnt/hops /srv/hops"
	fi
    fi

    WORKER_GPUS=$(ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo lspci | grep -i nvidia | wc -l")
    # strip carriage return '\r' from variable to make it a number
    WORKER_GPUS=$(echo $WORKER_GPUS|tr -d '\r')


    echo ""
    echo "Number of GPUs found on worker: $WORKER_GPUS"
    echo ""
    if [ "$WORKER_GPUS" -gt "0" ] ; then
	HAS_GPUS=1
	if [ "$WORKER_DEFAULTS" != "true" ] ; then
	    printf 'Do you want all of the GPUs to be used by this worker (y/n (default y):'
	    read ACCEPT
	    if [ "$ACCEPT" == "y" ] || [ "$ACCEPT" == "yes" ] || [ "$ACCEPT" == "" ] ; then
		echo "$WORKER_GPUS will be used on this worker."
		# if [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "os" ] ; then
		# 	   echo "Installing kernel-devel on worker.."
		# 	   ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo yum install \"kernel-devel-uname-r == $(uname -r)\" -y" > /dev/null
		# fi
	    else
		echo "$The GPUs will not be used on this worker."
		WORKER_GPUS=0
	    fi
	    #       else
	    #	   ssh -t -o StrictHostKeyChecking=no $WORKER_IP "sudo yum install \"kernel-devel-uname-r == $(uname -r)\" -y" > /dev/null
	fi
    else
	echo "No worker GPUs available"
    fi

    tmpYml="cluster-defns/.worker.yml"
    if [ "$WORKER_GPUS" -gt "0" ] ; then
	echo "GPU Worker YML"
	cat $WORKER_GPU_YML > $tmpYml
	update_worker_yml
    else
	echo "CPU Worker YML"
	cat $WORKER_YML > $tmpYml
	update_worker_yml
    fi

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
       # Azure mounts disks here: /mnt/reosurce
       if [ "$CLOUD" == "azure" ] ; then
	   sudo mkdir -p /mnt/resource/hops
	   sudo rm -rf /srv/hops
	   sudo ln -s /mnt/resource/hops /srv/hops
       else
       # AWS/GCP mount disks here: /mnt
	   sudo mkdir -p /mnt/hops
	   sudo rm -rf /srv/hops
	   sudo ln -s /mnt/hops /srv/hops
       fi
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
   sudo rm -rf /srv/hops
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
              echo "usage: [sudo] ./$SCRIPTNAME "
	      echo " [-h|--help]      help message"
	      echo " [-i|--install-action localhost|localhost-tls|cluster|enterprise|karamel|purge|purge-all] "
	      echo "                 'localhost' installs a localhost Hopsworks cluster"
	      echo "                 'localhost-tls' installs a localhost Hopsworks cluster with TLS enabled"
	      echo "                 'cluster' installs a multi-host Hopsworks cluster"
	      echo "                 'enterprise' installs a multi-host Enterprise  Hopsworks cluster"
	      echo "                 'kubernetes' installs a multi-host Enterprise Hopsworks cluster with Kubernetes"
	      echo "                 'karamel' installs and starts Karamel"
	      echo "                 'purge' removes Hopsworks completely from this host"
	      echo "                 'purge-all' removes Hopsworks completely from ALL hosts"
	      echo " [-cl|--clean]    removes the karamel installation"
	      echo " [-dr|--dry-run]  does not run karamel, just generates YML file"
#	      echo " [--gcp-nvme 0-9  number of NVMe disks to mount on worker nodes"
	      echo " [-c|--cloud      on-premises|gcp|aws|azure]"
	      echo " [-w|--workers    IP1,IP2,...,IPN|none] install on workers with IPs in supplied list (or none). Uses default mem/cpu/gpus for the workers."
	      echo " [-d|--download-enterprise-url url] downloads enterprise binaries from this URL."
	      echo " [-dc|--download-url] downloads binaries from this URL."
	      echo " [-du|--download-user username] Username for downloading enterprise binaries."
	      echo " [-dp|--download-password password] Password for downloading enterprise binaries."
	      echo " [-ni|--non-interactive)] skip license/terms acceptance and all confirmation screens."
	      echo " [-p|--https-proxy) url] URL of the https proxy server. Only https (not http_proxy) with valid certs supported."
	      echo " [-pwd|--password password] sudo password for user running chef recipes."
	      echo " [-y|--yml yaml_file] yaml file to run Karamel against."
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
	      ENTERPRISE_USER=$1
	      ;;
    -dp|--download-password)
      	      shift
	      ENTERPRISE_PASSWORD=$1
	      ;;
    -dr|--dry-run)
	      DRY_RUN=1
	      ;;
    # -gn|--gcp-nvme)
    # 	      NUM_GCP_NVME_DRIVES_PER_WORKER=$1
    # 	      GCP_NVME=1
    # 	      ;;
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
    -p|--http-proxy)
              shift
              PROXY=$1
              set_karamel_http_proxy
	      ;;
    -w|--workers)
              shift
              WORKER_LIST=$1
              ;;
    -y|--yml)
              shift
              yml=$1
              ;;
    -pwd|--password)
	      shift
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

which lspci > /dev/null
if [ $? -ne 0 ] ; then
    # this only happens on centos
   echo "Installing pciutils ...."
   sudo yum install pciutils -y > /dev/null
fi
AVAILABLE_GPUS=$(sudo lspci | grep -i nvidia | wc -l)


if [ $NON_INTERACT -eq 0 ] ; then
    splash_screen
    display_license
    accept_license
    clear_screen

    # Check if a proxy server is needed to access the internet.
    # If yes, set the http(s)_proxy environment variable when starting karamel
    if [ "$http_proxy" == "" ] ; then
	if [ "$https_proxy" == "" ] ; then
	   check_proxy
	else
           PROXY=$https_proxy	    
           set_karamel_http_proxy
	fi
    else
	PROXY=$http_proxy
	set_karamel_http_proxy
    fi
    clear_screen
    enter_email
    clear_screen
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
    IPS=$(grep 'ip:' hopsworks-installation.yml | awk '{ print $2 }')
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

if [ $DRY_RUN -eq 0 ] ; then
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
	elif [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "os" ] ; then
	    sudo yum install java-1.8.0-openjdk-headless -y
	    sudo yum install wget -y
	else
	    echo "Could not recognize Linux distro: $DISTRO"
	    exit_error
	fi
    fi

    # if [ $GCP_NVME -eq 1 ] ; then
    #     for (( i=1; i<=${NUM_GCP_NVME_DRIVES_PER_WORKER}; i++ ))
    #     do
    # 	  sudo mkdir -p /mnt/nvmeDisks/nvme${i}
    #       sudo mkfs.ext4 -F /dev/nvme0n${i}
    #     done
    # fi

    install_dir
fi



if [ ! -d cluster-defns ] ; then
    mkdir cluster-defns
fi
cd cluster-defns
# Don't overwrite the YML files, so that users can customize them
wget -nc ${CLUSTER_DEFINITION_BRANCH}/$INPUT_YML
wget -nc ${CLUSTER_DEFINITION_BRANCH}/$WORKER_YML
wget -nc ${CLUSTER_DEFINITION_BRANCH}/$WORKER_GPU_YML
cd ..

if [ "$INSTALL_ACTION" == "$INSTALL_CLUSTER" ] || [ "$INSTALL_ACTION" == "$INSTALL_LOCALHOST" ] || [ "$INSTALL_ACTION" == "$INSTALL_LOCALHOST_TLS" ]  ; then
    clear_screen
    enter_cloud
    cp -f $INPUT_YML $YML_FILE
fi

if [ "$CLOUD" == "azure" ] ; then
    NSLOOKUP=$(nslookup $IP | grep name | awk {' print $4 '} | grep -v 'internal.cloudapp.net')
    SUSPECTED_HOSTNAME=${NSLOOKUP::-1}
    echo ""
    echo "On Azure, you need to add every host to the same Private DNS Zone, and note the hostname you set in Azure."
    echo "We suspect the private DNS hostname is:"
    echo "    $SUSPECTED_HOSTNAME"
    echo ""
    if [ $NON_INTERACT -eq 0 ] ; then
      printf 'Please enter the private DNS hostname for this head node (default:'
      echo -n " $SUSPECTED_HOSTNAME):"
      read PRIVATE_HOSTNAME
    fi
    if [ "$PRIVATE_HOSTNAME" == "" ] ; then
      PRIVATE_HOSTNAME=$SUSPECTED_HOSTNAME
    fi
    sudo hostname $PRIVATE_HOSTNAME
    clear_screen
fi

if [ $DRY_RUN -eq 0 ] ; then
    if [ ! -d karamel-${KARAMEL_VERSION} ] ; then
	echo "Installing Karamel..."
	clear_screen
	wget -nc http://www.karamel.io/sites/default/files/downloads/karamel-${KARAMEL_VERSION}.tgz
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
fi

if [ "$INSTALL_ACTION" == "$INSTALL_CLUSTER" ] ; then
  if [ "$WORKER_LIST" == "" ] ; then
      worker_size
  else
      WORKER_DEFAULTS="true"
      if [ "$WORKER_LIST" != "none" ] ; then
	  IFS=',' read -r -a workers <<< "$WORKER_LIST"
	  echo "Workers:   ${workers[*]}"
	  for worker in "${workers[@]}"
	  do
	      WORKER_IP=$worker
	      add_worker
	  done
      fi
  fi
fi

if [ "$INSTALL_ACTION" == "$INSTALL_LOCALHOST_TLS" ] ; then
  TLS="true"
fi

if [ "$INSTALL_ACTION" == "$INSTALL_KARAMEL" ]  ; then
    cd karamel-${KARAMEL_VERSION}
    $KARAMEL_HTTP_PROXY_1
    $KARAMEL_HTTP_PROXY_2
    $KARAMEL_HTTP_PROXY_3    
    setsid ./bin/karamel -headless &
    echo "To access Karamel, open your browser at: "
    echo ""
    echo "http://${ip}:9090/index.html"
    echo ""
else
    if [ $DRY_RUN -eq 0 ] ; then
	sudo -n true
	if [ $? -ne 0 ] ; then
	    echo ""
	    echo "It appears you need a sudo password for this account."
            echo "Enter the sudo password for $USER: "
	    read -s passwd
            SUDO_PWD="-passwd $passwd"
	    echo ""
	fi
    fi

    if [ $AVAILABLE_GPUS -gt 0 ] ; then
	    CUDA="cuda:
    accept_nvidia_download_terms: true"
    fi

    if [ $HAS_GPUS -eq 1 ] ; then
	YARN="capacity:
      resource_calculator_class: org.apache.hadoop.yarn.util.resource.DominantResourceCalculatorGPU
    yarn:
      cgroups_strict_resource_usage: 'false'
      gpus: '*'"
    fi

    if [ $DRY_RUN -eq 0 ] ; then
	DNS_IP=$(sudo cat /etc/resolv.conf | grep ^nameserver | awk '{ print $2 }' | tail -1)
    fi
    BASE_PWD=$(date | md5sum | head -c${1:-8})
    GBS=$(expr $AVAILABLE_MEMORY - 2)
    MEM=$(expr $GBS \* 1024)
    perl -pi -e "s/__CLOUD__/$CLOUD/" $YML_FILE
    perl -pi -e "s/__MEM__/$MEM/" $YML_FILE
    perl -pi -e "s/__PWD__/$BASE_PWD/g" $YML_FILE
    perl -pi -e "s/__DNS_IP__/$DNS_IP/g" $YML_FILE
    CPUS=$(expr $AVAILABLE_CPUS - 1)
    perl -pi -e "s/__CPUS__/$CPUS/" $YML_FILE
    # escape slashes to use perl -e
    HOPSWORKS_REPO=$(echo "$HOPSWORKS_REPO"  | sed 's/\//\\\//g')
    perl -pi -e "s/__GITHUB__/$HOPSWORKS_REPO/" $YML_FILE
    perl -pi -e "s/__BRANCH__/$HOPSWORKS_BRANCH/" $YML_FILE
    perl -pi -e "s/__USER__/$USER/" $YML_FILE
    perl -pi -e "s/__IP__/$IP/" $YML_FILE
    perl -pi -e "s/__YARN__/$YARN/" $YML_FILE
    perl -pi -e "s/__TLS__/$TLS/" $YML_FILE
    perl -pi -e "s/__CUDA__/$CUDA/" $YML_FILE

    if [ "$DOWNLOAD_URL" != "" ] ; then
       DOWNLOAD="download_url: $DOWNLOAD_URL"
    fi

    if [ $ENTERPRISE -eq 1 ] ; then
	if [ "$ENTERPRISE_DOWNLOAD_URL" = "" ] ; then
	    echo ""
            printf "Enter the URL to download the Enterprise Binaries from: "
	    read ENTERPRISE_DOWNLOAD_URL
        fi
	if [ "$ENTERPRISE_USER" = "" ] ; then
	    echo ""
            printf "Enter the Enterprise URL username: "
	    read ENTERPRISE_USER
        fi
	if [ "$ENTERPRISE_PASSWORD" = "" ] ; then
	    echo ""
            printf "Enter the Enterprise URL password: "
	    read -s ENTERPRISE_PASSWORD
        fi
	# Escape URL
	ENTERPRISE_DOWNLOAD_URL=${ENTERPRISE_DOWNLOAD_URL//\./\\\.}
	ENTERPRISE_DOWNLOAD_URL=${ENTERPRISE_DOWNLOAD_URL//\//\\\/}
        echo ""
	#printf -v DNS_IP "%q\n" "$DNS_IP"
	DNS_IP=${DNS_IP//\./\\\.}
	if [ $KUBERNETES -eq 1 ] ; then
	    KUBE="true"
	    DOWNLOAD="$DOWNLOAD
  kube-hops:
    pki:
      verify_hopsworks_cert: false
    fallback_dns: $DNS_IP
    master:
      untaint: true
"
	    KUBERNETES_RECIPES="      - kube-hops::hopsworks
      - kube-hops::ca
      - kube-hops::master
      - kube-hops::addons"
	fi
        ENTERPRISE_ATTRS="enterprise:
      install: true
      download_url: $ENTERPRISE_DOWNLOAD_URL
      username: $ENTERPRISE_USER
      password: $ENTERPRISE_PASSWORD"

    fi
    perl -pi -e "s/__ENTERPRISE__/$ENTERPRISE_ATTRS/" $YML_FILE
    perl -pi -e "s/__DOWNLOAD__/$DOWNLOAD/" $YML_FILE
    perl -pi -e "s/__KUBERNETES_RECIPES__/$KUBERNETES_RECIPES/" $YML_FILE
    perl -pi -e "s/__KUBE__/$KUBE/" $YML_FILE

    if [ $DRY_RUN -eq 0 ] ; then
	cd karamel-${KARAMEL_VERSION}
	echo "Running command from ${PWD}:"
	echo "$KARAMEL_HTTP_PROXY_1"
	echo "$KARAMEL_HTTP_PROXY_2"
	echo "$KARAMEL_HTTP_PROXY_3"	
	echo "setsid ./bin/karamel -headless -launch ../$YML_FILE $SUDO_PWD > ../installation.log 2>&1 &"
        $KARAMEL_HTTP_PROXY_1
        $KARAMEL_HTTP_PROXY_2
        $KARAMEL_HTTP_PROXY_3    
	setsid ./bin/karamel -headless -launch ../$YML_FILE $SUDO_PWD > ../installation.log 2>&1 &
	echo ""
	echo "***********************************************************************************************************"
	echo ""
	echo "Installation has started, but may take 1 hour or more.........."
	echo ""
	echo "The Karamel installer UI will soon start at:  http://${IP}:9090/index.html"
	echo "Note: port 9090 must be open for external traffic and Karamel will shutdown when installation finishes."
	echo ""
	echo "====================================================================="
        echo "Hopsworks will later be available at private IP:"
	echo ""
	echo "https://${IP}/hopsworks"
	echo ""
	echo "====================================================================="
	echo ""
	echo "You can view the installation logs with this command:"
	echo ""
	echo "tail -f installation.log"
	echo ""
	echo "***********************************************************************************************************"
	cd ..
    fi
fi


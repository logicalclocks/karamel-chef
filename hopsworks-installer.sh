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

yml=cluster-defns/hopsworks-installer.yml

HOPSWORKS_VERSION=1.3.0-SNAPSHOT
HOPSWORKS_BRANCH=karamel_installer
KARAMEL_VERSION=0.6
INSTALL_ACTION=
NON_INTERACT=0
SCRIPTNAME=`basename $0`
AVAILABLE_MEMORY=$(free -g | grep Mem | awk '{ print $2 }')
AVAILABLE_DISK=$(df -h | grep '/$' | awk '{ print $4 }')
AVAILABLE_MNT=$(df -h | grep '/mnt$' | awk '{ print $4 }')
AVAILABLE_CPUS=$(cat /proc/cpuinfo | grep '^processor' | wc -l)
which nvidia-smi
if [ $? -eq 0 ] ; then
    AVAILABLE_GPUS=$(nvidia-smi -L | wc -l)
else
    AVAILABLE_GPUS=0
fi    
IP=$(hostname -I | awk '{ print $1 }')
DISTRO=
WORKER_ID=0
DRY_RUN=0
CLEAN_INSTALL_DIR=0
SUDO_PWD=
INSTALL_LOCALHOST=1
INSTALL_CLUSTER=2
INSTALL_KARAMEL=3
INSTALL_NVIDIA=4
PURGE_HOPSWORKS=5
CLOUD=
GCP_NVME=0
RM_CLASS="hops:
    yarn:"


if [ $AVAILABLE_GPUS -gt 0 ] ; then
RM_CLASS="cuda:
    accept_nvidia_download_terms: true
  hops:
    capacity: 
      resource_calculator_class: org.apache.hadoop.yarn.util.resource.DominantResourceCalculatorGPU
    yarn:
      gpus: '*'"
  
fi    

# $1 = String describing error
exit_error() 
{
  #CleanUpTempFiles

  echo "" $ECHO_OUT
  echo "Error number: $1" $ECHO_OUT
  echo "Exiting $PRODUCT $VERSION installer." $ECHO_OUT
  echo "" $ECHO_OUT
  exit 1
}

# $1 = accept phrase (what to accept)
# caller reads $ENTERED_STRING global variable for result
enter_string() 
{
     echo "$1" $ECHO_OUT
     read ENTERED_STRING
}

###################################################################################################
# SCREEN CLEAR FUNCTIONS
###################################################################################################

clear_screen()
{
 if [ $NON_INTERACT -eq 0 ] ; then
   echo "" $ECHO_OUT
   echo "Press ENTER to continue" $ECHO_OUT
   read cont < /dev/tty
 fi 
 clear
}

clear_screen_no_skipline()
{
 if [ $NON_INTERACT -eq 0 ] ; then
    echo "Press ENTER to continue" $ECHO_OUT
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
  echo "" $ECHO_OUT
  echo "Karamel/Hopsworks Installer, Copyright(C) 2020 Logical Clocks AB. All rights reserved." $ECHO_OUT
  echo "" $ECHO_OUT
  echo "This program can install Karamel/Chef and/or Hopsworks." $ECHO_OUT
  echo "" $ECHO_OUT
  echo "To cancel installation at any time, press CONTROL-C"  $ECHO_OUT
  echo "" $ECHO_OUT  
  echo "You appear to have following setup on this host:"
  echo "* available memory: $AVAILABLE_MEMORY"
  echo "* available disk space (on '/' root partition): $AVAILABLE_DISK"
  echo "* available disk space (on '/mnt' partition): $AVAILABLE_MNT"  
  echo "* available CPUs: $AVAILABLE_CPUS"
  echo "* available GPUS: $AVAILABLE_GPUS"  
  echo "* your ip is: $IP"
  echo "* installation user: $USER"
  echo "* linux distro: $DISTRO"
  hname=$(hostname -f)
  strlen=${#hname}
  if [ $strlen -gt 64 ] ; then
      echo ""
      echo "WARNING: hostname is longer 64 chars which can cause problems with OpenSSL: $hname"
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
  echo ""  $ECHO_OUT
  echo "This code is released under the GNU General Public License, Version 3, see:" $ECHO_OUT
  echo "http://www.gnu.org/licenses/gpl-3.0.txt" $ECHO_OUT
  echo "" $ECHO_OUT
  echo "Copyright(C) 2020 Logical Clocks AB. All rights reserved." $ECHO_OUT
  echo "Logical Clocks AB is furnishing this item "as is". Logical Clocks AB does not provide any" $ECHO_OUT
  echo "warranty of the item whatsoever, whether express, implied, or statutory," $ECHO_OUT
  echo "including, but not limited to, any warranty of merchantability or fitness" $ECHO_OUT
  echo "for a particular purpose or any warranty that the contents of the item will" $ECHO_OUT
  echo "be error-free. In no respect shall Logical Clocks AB incur any liability for any" $ECHO_OUT 
  echo "damages, including, but limited to, direct, indirect, special, or consequential" $ECHO_OUT
  echo "damages arising out of, resulting from, or any way connected to the use of the" $ECHO_OUT
  echo "item, whether or not based upon warranty, contract, tort, or otherwise; " $ECHO_OUT 
  echo "whether or not injury was sustained by persons or property or otherwise;" $ECHO_OUT
  echo "and whether or not loss was sustained from, or arose out of, the results of," $ECHO_OUT
  echo "the item, or any services that may be provided by Logical Clocks AB." $ECHO_OUT
  echo "" $ECHO_OUT
  printf 'Do you accept these terms and conditions? [ yes or no ] '
}
  
accept_license () 
  {
    read ACCEPT
    case $ACCEPT in
      yes | Yes | YES)
        ;;
	no | No | NO)
        echo "" $ECHO_OUT
        exit 0
        ;;
      *)
        echo "" $ECHO_OUT
        echo "Please enter either 'yes' or 'no'." $ECHO_OUT
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
(1) Setup and start a localhost Hopsworks cluster using Karamel. The cluster will run on this machine. \n
    \tThe binaries and directories for storing data will all be under /srv/hops.\n
    \tHopsworks will run at the end of the installation.\n
(2) Setup and start a multi-host Hopsworks cluster using Karamel. The cluster will run on all the machines. \n
    \tHopsworks will run at the end of the installation.\n
(3) Setup, install, and run Karamel on this host. \n
    \tKaramel can be used to install Hopsworks by opening the URL in your browser: http://${ip}:9090/index.html \n
"
}

install_action()
{
    if [ "$INSTALL_ACTION" = "" ] ; then

        echo "-------------------- Installation Options --------------------" $ECHO_OUT
	echo "" $ECHO_OUT
        echo "What would you like to do?" $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(1) Setup a Hopsworks cluster on only this host." $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(2) Setup a Hopsworks cluster using more than 1 host." $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(3) Install and start Karamel." $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(4) Install Nvidia drivers and reboot server." $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(5) Purge (uninstall) Hopsworks from this host." $ECHO_OUT
	echo "" $ECHO_OUT	
	printf 'Please enter your choice '1', '2', '3', 'q' \(quit\), or 'h' \(help\) :  '
        read ACCEPT
        case $ACCEPT in
          1)
	    INSTALL_ACTION=$INSTALL_LOCALHOST
            ;;
          2)
	    INSTALL_ACTION=$INSTALL_CLUSTER
            ;;
          3)
	    INSTALL_ACTION=$INSTALL_KARAMEL
            ;;
          4)
	    INSTALL_ACTION=$INSTALL_NVIDIA
            ;;
          5)
	    INSTALL_ACTION=$PURGE_HOPSWORKS
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
            echo "" $ECHO_OUT
            echo "Invalid Choice: $ACCEPT" $ECHO_OUT
            echo "Please enter your choice '1', '2', '3', '4', 'q', or 'h'." $ECHO_OUT
	    clear_screen
            install_action
            ;;
         esac
	clear_screen
   fi
}


enter_cloud()
{
    if [ "$CLOUD" = "" ] ; then

        echo "-------------------- Where are you installing Hopsworks? --------------------" $ECHO_OUT
	echo "" $ECHO_OUT
        echo "On what platform are you installing Hopsworks?" $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(1) On-premises or private cloud." $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(2) AWS." $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(3) GCP." $ECHO_OUT
	echo "" $ECHO_OUT
	echo "(4) Azure." $ECHO_OUT
	echo "" $ECHO_OUT
	printf 'Please enter your choice '1', '2', '3', '4' :  '
        read ACCEPT
        case $ACCEPT in
          1)
	    CLOUD=
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
            echo "" $ECHO_OUT
            echo "Invalid Choice: $ACCEPT" $ECHO_OUT
            echo "Please enter your choice '1', '2', '3', '4'." $ECHO_OUT
	    clear_screen
            enter_cloud
            ;;
         esac
	clear_screen
   fi
}


add_worker()
{
   printf 'Please enter the number of workers you want to add (default: 0): '
   read WORKER_IP

   ssh -t -o StrictHostKeyChecking=no $WORKER_IP "whoami" > /dev/null
   if [ $? -ne 0 ] ; then
      echo "Failed to ssh using public into: ${USER}@${WORKER_IP}"
      echo "Cannot add worker node, as you need to be able to ssh into it using your public key"
      exit_error
   fi

   printf 'Please enter the amout of memory in this worker that is to be used by YARN in GBs: '
   read GBS

   MBS=$(expr $GBS \* 1024)
   printf 'Please enter the number of CPUs in this worker to be used by YARN:'
   read CPUS
   
echo "  
  datanode${WORKER_ID}:
    size: 1
    baremetal:
      ip: ${WORKER_IP}
    attrs:
      hops:
        yarn:
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
      - hopsmonitor::purge_telegraf

" >> $YML_CLUSTER $ECHO_OUT

if [ $? -ne 0 ] ; then
 echo "" $ECHO_OUT
 echo "Failure: could not add a worker to the yml cnf file: $YML_CLUSTER" $ECHO_OUT
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
   i=0
   while $i -lt $NUM_WORKERS
   do
      add_worker
      i=$((i+1))
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
  if [ "X$USERID" = "Xroot" ]; then
    exit_error "This script only works for non-root users."
  fi
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
	      echo "" $ECHO_OUT
	      echo "You can install Karamel asa normal user." $ECHO_OUT
              echo "usage: [sudo] ./$SCRIPTNAME "
	      echo " [-h|--help]      help for ndbinstaller.sh" $ECHO_OUT
	      echo " [-i|--install-action localhost|cluster|karamel] " $ECHO_OUT
	      echo "                 'localhost' installs a localhost Hopsworks cluster"
	      echo "                 'cluster' installs a multi-host Hopsworks cluster"
	      echo "                 'karamel' installs and starts Karamel"
	      echo "                 'purge' removes Hopsworks completely from this host"	      
	      echo " [-cl|--clean]    removes the karamel installation"
	      echo " [-dr|--dry-run]      does not run karamel, just generates YML file"
	      echo " [--gcp-nvme]     mount NVMe disk on GCP node"	      
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
		 cluster)
		      INSTALL_ACTION=$INSTALL_CLUSTER
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
fi

install_action

if [ "$INSTALL_ACTION" == "$INSTALL_NVIDIA" ] ; then
   sudo -- sh -c 'echo "blacklist nouveau
     options nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf'
   sudo update-initramfs -u
   echo "Rebooting....."
   sudo reboot
fi    

if [ "$INSTALL_ACTION" == "$PURGE_HOPSWORKS" ] ; then
   
   cd
   echo "Shutting down services..."
   if sudo test -f "/srv/hops/kagent/kagent/bin/shutdown-all-local-services.sh"  ; then
     sudo /srv/hops/kagent/kagent/bin/shutdown-all-local-services.sh -f > /dev/null
   fi
   echo "Killing karamel..."
   pkill java
   echo "Removing karamel..."   
   rm -rf karamel*
   echo "Removing cookbooks..."   
   sudo rm -rf .karamel   
   sudo rm -rf /tmp/chef-solo/cookbooks
   echo "Purging old installation..."      
   sudo rm -rf /srv/hops/*
   exit 0
fi    

if [ "$INSTALL_ACTION" == "$INSTALL_CLUSTER" ] || [ "$INSTALL_ACTION" == "$INSTALL_LOCALHOST" ] ; then
  enter_cloud
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
  pushd .
  cd ~/.ssh
  cat id_rsa.pub >> authorized_keys > /dev/null
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
	sudo apt update -y > /dev/null
	sudo apt install openjdk-8-jre-headless -y > /dev/null
    elif [ "$DISTRO" == "centos" ] ; then
	sudo yum install java-1.8.0-openjdk-headless -y > /dev/null
	sudo yum install wget -y > /dev/null
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
	echo "It appears you need a sudo password for this account."
        echo -n "Enter the sudo password for $USER: "
	read -s passwd
        SUDO_PWD="-passwd $passwd"
	echo ""
    fi

    if [ ! -d cluster-defns ] ; then
	mkdir cluster-defns
	cd cluster-defns
	wget https://raw.githubusercontent.com/logicalclocks/karamel-chef/${HOPSWORKS_BRANCH}/cluster-defns/hopsworks-installer.yml
	cd ..
    fi
    DNS_IP=$(sudo cat /etc/resolv.conf | grep ^nameserver | awk '{ print $2 }' | tail -1)
    BASE_PWD=$(date | md5sum | head -c${1:-8})
    cp -f $yml cluster-defns/hopsworks-installer-active.yml
    GBS=$(expr $AVAILABLE_MEMORY - 2)
    MEM=$(expr $GBS \* 1024)    
    perl -pi -e "s/__CLOUD__/$CLOUD/" cluster-defns/hopsworks-installer-active.yml
    perl -pi -e "s/__MEM__/$MEM/" cluster-defns/hopsworks-installer-active.yml
    perl -pi -e "s/__PWD__/$BASE_PWD/g" cluster-defns/hopsworks-installer-active.yml
    perl -pi -e "s/__DNS_IP__/$DNS_IP/g" cluster-defns/hopsworks-installer-active.yml        
    CPUS=$(expr $AVAILABLE_CPUS - 1)
    perl -pi -e "s/__CPUS__/$CPUS/" cluster-defns/hopsworks-installer-active.yml
    perl -pi -e "s/__VERSION__/$HOPSWORKS_VERSION/" cluster-defns/hopsworks-installer-active.yml
    perl -pi -e "s/__BRANCH__/$HOPSWORKS_BRANCH/" cluster-defns/hopsworks-installer-active.yml    
    perl -pi -e "s/__USER__/$USER/" cluster-defns/hopsworks-installer-active.yml
    perl -pi -e "s/__IP__/$IP/" cluster-defns/hopsworks-installer-active.yml
    perl -pi -e "s/__RM_CLASS__/$RM_CLASS/" cluster-defns/hopsworks-installer-active.yml
  if [ $DRY_RUN -eq 0 ] ; then
    cd karamel-${KARAMEL_VERSION}
    echo "Running command from ${PWD}:"
    echo " nohup ./bin/karamel -headless -launch ../cluster-defns/hopsworks-installer-active.yml $SUDO_PWD &"
    nohup ./bin/karamel -headless -launch ../cluster-defns/hopsworks-installer-active.yml $SUDO_PWD > ../installation.log &
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

#!/bin/bash
#-xv

###################################################################################################
#                                                                                                 #
# This code is released under the Apache Public License, Version 2, see for details:              #
# https://www.apache.org/licenses/LICENSE-2.0                                                     #
#                                                                                                 #
#                                                                                                 #
# Copyright (c) Logical Clocks AB, 2017.                                                           #
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


yml=1.8GB.yml
NON_INTERACT=0
HOPSWORKS_INSTALLER_VERSION="Hopsworks Localhost Installer Version 0.1 \n\nCopyright (c) Logical Clocks, 2017/18."
PARAM_INSTALL_DIR=0
PARAM_CLEAN_INSTALL_DIR=0
SCRIPTNAME=`basename $0`
SSH_PORT=22
KARAMEL_VERSION=0.5
NET_INTERFACE=""

#ECHO_OUT="2>&1 > /dev/null"
ECHO_OUT="2>&1 > /tmp/hopsworks-installer.log"

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

public_key=""

function finish {
  grep "$public_key" ${HOME}/.ssh/authorized_keys 2>&1 > /dev/null
  # if [ $? -eq 0 ] ; then
  #   grep -v "$public_key" $HOME/.ssh/authorized_keys > $HOME/.ssh/tmp 
  #   mv $HOME/.ssh/tmp $HOME/.ssh/authorized_keys
  # fi    
}
trap finish EXIT



#######################################################################
# Introduction Splash Screen
#######################################################################

splash_screen() 
{
  clear
  echo "" 
  echo "$HOPSWORKS_INSTALLER_VERSION"
  echo ""
  echo "This program installs the Hopsworks platform."
  echo ""
  echo "Note: ~5GB of data will be downloaded - don't do this on a smartuphone link."  
  echo "" 
  if [ $ROOTUSER -eq 1 ] ; then
    echo "You are running the Installer as a root user." 
  fi
  echo "Hopsworks will install by default to: /srv/hops/"
  echo "To install to a different directory, pass in the -d option"
  echo "e.g., ./hopsinstaller.sh -d /opt/hops"
  echo ""  
  echo "To cancel installation at any time, press CONTROL-C"  
  
  clear_screen
}

copyrights() 
{
  clear
  echo ""
  echo "This program installs a number of third-party open source platforms."
  echo ""      
  echo "By agreeing to the terms and conditions below, you agree to all licensing by these frameworks."
  echo "Apache products: Kafka, Flink, Spark, Livy, Zeppelin, Zookeeper: all Apache v2 licensed."  
  echo "Elasticsearch, Kibana, Logstash, Copyright(C) Elastic"
  echo "Dr Elephant, Copyright(C) LinkedIn, Apache v2 licensed."
  echo "Tensorflow, Copyright(C) Google, Apache v2 licensed."
  echo "Grafana, Copyright(C) Torkel Ödegaard, Raintank Inc., Apache v2 licensed."
  echo "InfluxDB, Copyright(C) Errplane Inc., MIT license."
  echo "Do you agree to download these products and their open-source licenses?"
  clear_screen
}

oracle_download()
{
  clear
  echo ""    
  echo "You will also need to download a database driver and database for Hops."
  echo ""      
  echo "Hops currently suppports MySQL Server and NDB Storage Engine (MySQL Cluster), Copyright(C) Oracle, GPL v2 licensed."
  echo "By clicking enter, you indicated that you want to download GPL v2 licensed MySQL Cluster."
  clear_screen
}

nvidia_download()
{
  clear
  echo ""    
  echo "You will also need to download Nvidia drivers (cuda) and libraries (cudnn)."
  echo "By entering 'yes', you indicate that you agree with Nvidia's terms and conditions, see http://nvidia.com."
  echo ""
  echo "Please enter either 'yes' or 'no'." 
  printf 'Do you want to install Nvidia Cuda and Cudnn libraries? [ yes or no ] '
  use_gpu="true"
  read ACCEPT
  case $ACCEPT in
    yes | Yes | YES)
      ;;
    no | No | NO)
      use_gpu="false"
      ;;
    *)
      echo "" 
      echo "Please enter either 'yes' or 'no'." 
      printf 'Do you want to install Nvidia Cuda and Cudnn libraries? [ yes or no ] '
      nvidia_download
    ;;
  esac

  clear_screen
}


enable_services()
{
  clear
  echo ""    
  echo "Do you want to enable Hops Services as daemons that start automatically when the computer starts?"
  printf 'Do you enable Hops services as daemons? [ yes or no ] '
  enable_services="false"  
  read ACCEPT
  case $ACCEPT in
      yes | Yes | YES)
	  enable_services="true"
      ;;
    no | No | NO)
      ;;
    *)
      echo "" 
      echo "Please enter either 'yes' or 'no'." 
      printf 'Do you enable Hops services as daemons? [ yes or no ] '
      enable_services
    ;;
  esac

  clear_screen
}


display_license()
{
  echo ""        
  echo "Support is available at http://www.logicalclocks.com/" 
  echo ""  
  echo "This code is released under the Apache License, Version 2, see:" 
  echo "https://www.apache.org/licenses/LICENSE-2.0"
  echo "" 
  echo "$HOPSWORKS_INSTALLER_VERSION"
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
  

  
SUDO_PWD=
enter_sudo_password () 
{
 echo ""
 echo "Enter the sudo password for user $USER (press enter, if there is no sudo password):"
 read -s ACCEPT
 if [ "$ACCEPT" != "" ] ; then
   SUDO_PWD="-passwd $ACCEPT"
 fi
 echo -n "$ACCEPT" | sudo -S ls / > /dev/null
 if [ $? -ne 0 ] ; then
     echo "Your sudo password was incorrect. Exiting..."
     exit 33
 fi    
 
}
  

#
# Checks if you are running the script as root or not
#
check_userid()
{
  ROOTUSER=0
  # Check if user is root
  USERID=`id | sed -e 's/).*//; s/^.*(//;'`
  if [ "X$USERID" = "Xroot" ]; then
    ROOTUSER=1
  else
    HOMEDIR=`(cd ; pwd)`
    USERNAME=$USERID
  fi
}

check_userid


while [ $# -gt 0 ]; do    # Until you run out of parameters . . .
  case "$1" in
    -h|--help|-help)
	      echo "" 
	      echo "You can install Hopsworks as 'root' or normal user." 
	      echo "Install as normal user to install to user directories [~/.mysql]." 
	      echo "" 
              echo "usage: [sudo] ./$SCRIPTNAME "
	      echo " [-c|--clean]    clean the install directory when installing"
	      echo " [-ni|--non-interactive]    skip all the license/accept screens"
	      echo " [--network-interface]      name of network interface to use (e.g., 'eth0')"
	      echo " [-d|--dir INSTALL DIRECTORY]"
	      echo "                  set the base installation directory "
	      echo " [-v|--version]   version information" 
	      echo "" 
	      exit 3
              break ;;
    -c|--clean)
	      CLEAN_INSTALL_DIR=1
	      ;;
    -d|--dir)
	      shift
	      PARAM_INSTALL_DIR=1
	      ;;
    --network-interface)
	      shift
	      NET_INTERFACE="$1"
	      ;;
    -ni|--non-interactive)
	      NON_INTERACT=1
	      ;;
    -pwd|--password)
	      SUDO_PWD= SUDO_PWD="-passwd $1"
	      ;;
    -v|--version) 
	      echo ""     
              echo -e $HOPSWORKS_INSTALLER_VERSION 
	      echo "" 
              exit 0
              break ;;
    *)
	  exit_error "Unrecognized parameter: $1"
	  ;;
  esac
  shift       # Check next set of parameters.
done


if [ $NON_INTERACT -eq 0 ] ; then
  splash_screen
  copyrights
  oracle_download
  nvidia_download
  enable_services  
  display_license  
  accept_license
  #  clear_screen
  enter_sudo_password
fi

which java
if [ $? -ne 0 ] ; then
    echo "Error."
    echo "You do not have Java installed."
    echo "You need to install Java, version 8 or greater."
    echo ""
    echo "Ubuntu/Debian installation instructions:"
    echo "sudo apt-get install openjdk-8-jdk"
    echo ""
    echo "Centos/Redhat installation instructions:"
    echo "sudo yum install java-1.8.0-openjdk"
    echo ""    
    exit 33
fi    

sudo systemctl reset-failed


sudo netstat -ltpn | grep 8080 2>&1 > /dev/null
if [ $? -eq 0 ] ; then
    echo "You have a service running on port 8080, needed by hopsworks. Please stop it, Hopsworks wants to run on port 8080."
    echo "If you can't stop the service, you will need to edit this bash script and the cluster definition file: cluster-definitions/${yml}"
    echo "sudo netstat -ltpn | grep 8080"
    echo ""
    exit 2
fi    

sudo netstat -ltpn | grep 4848 2>&1 > /dev/null
if [ $? -eq 0 ] ; then
    echo "You have a service running on port 4848, needed by hopsworks. Please stop it:"
    echo "sudo netstat -ltpn | grep 4848"
    echo ""
    exit 2
fi    

sudo netstat -ltpn | grep 3306 2>&1 > /dev/null
if [ $? -eq 0 ] ; then
    echo "You have a mysql server running on port 3306, needed by hopsworks. Please stop it (or better still, uninstall it)."
    echo "Maybe this will work to stop it: sudo systemctl stop mysqld"
    echo "Maybe this will work to uninstall it: sudo apt-get purge mysqld"
    exit 2
fi    


pushd .
# 1. setup ssh to localhost to sudo account

if [ ! -f ${HOME}/.ssh/id_rsa.pub ] ; then
    echo "No ssh keypair found. "
    echo "Generating a passwordless ssh keypair with ssh-keygen at ${HOME}/.ssh/id_rsa(.pub)"
    ssh-keygen -b 2048 -f ${HOME}/.ssh/id_rsa -t rsa -q -N ''
    if [ $? -ne 0 ] ; then
	echo "Problem generating a passwordless ssh keypair with the following command:"
	echo "ssh-keygen -b 2048 -f ${HOME}/.ssh/id_rsa -t rsa -q -N ''"
	echo "Exiting with error."
	exit 12
    fi
fi

public_key=$(cat ${HOME}/.ssh/id_rsa.pub)

grep "$public_key" ${HOME}/.ssh/authorized_keys
if [ $? -ne 0 ] ; then
    echo "Enabling ssh into localhost (needed by Karamel)"
    echo "Adding ${USERNAME} public key to ${HOME}/.ssh/authorized_keys"
    cat ${HOME}/.ssh/id_rsa.pub >> ${HOME}/.ssh/authorized_keys
fi

# 2. check if openssh server installed

echo "Check if openssh server installed and that ${USERNAME} can ssh without a password into ${USERNAME}@localhost"

ssh -p $SSH_PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${USERNAME}@localhost "echo 'ssh connected'" 

if [ $? -ne 0 ] ; then
    echo "Ssh server needs to be running on localhost. Starting one..."
    sudo service ssh restart 
    if [ $? -ne 0 ] ; then
	echo "Installing ssh server."
	sudo apt-get install openssh-server -y 
	sleep 2
        sudo service ssh status 
        if [ $? -ne 0 ] ; then
	    echo "Error: could not install/start a ssh server. Install an openssh-server (or some other ssh server) and re-run this install script."
	    echo "Exiting..."
	    exit 2
	fi
    fi
    ssh -p $SSH_PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${USERNAME}@localhost "echo 'hello'"
    if [ $? -ne 0 ] ; then    
      echo "Error: could not ssh to $USERNAME@localhost"
      echo "You need to setup you machine so that $USERNAME can ssh to localhost"
      echo "Exiting..."
      exit 3
    fi
fi    

#
# Sanity Checks
if [ -d ~/.berkshelf ] ; then
    sudo chown -R $USERNAME ~/.berkshelf
fi

java -version | grep '1.8'
if [ $? -ne 0 ] ; then
    echo "No java version 8 found. Installing..."
    sudo apt-get install openjdk-8-jre -y
fi

sudo rm -rf ${HOME}/.karamel/install
sudo rm -rf ${HOME}/.karamel/cookbooks

# 3. Download chefdk, karamel, and cluster.xml
mkdir -p ./hops 
cd hops
echo "Downloading and installing Karamel"

# ubuntu='14.04'
# chef-solo --help 2>&1 > /dev/null
# if [ $? -ne 0 ] ; then
#     grep '16.04' /etc/issue
#     if [ $? -ne 0 ] ; then
#        ubuntu='16.04'
#     fi
#     grep '16.10' /etc/issue
#     if [ $? -ne 0 ] ; then
#        ubuntu='16.04'
#     fi
#     echo "Downloading chefdk for ubuntu version $ubuntu"    
#     if [ ! -f chefdk_0.19.6-1_amd64.deb ] ; then
# 	wget https://packages.chef.io/files/stable/chefdk/0.19.6/ubuntu/16.04/chefdk_0.19.6-1_amd64.deb
# 	if [ $? -ne 0 ] ; then
# 	    echo "Could not download chefdk. Exiting..."
# 	    exit 4
# 	fi
#     fi
#     sudo dpkg -i chefdk_0.19.6-1_amd64.deb
#     if [ $? -ne 0 ] ; then
# 	echo "Retrying to download chefdk"
# 	rm -f chefdk_0.19.6-1_amd64.deb
# 	wget https://packages.chef.io/files/stable/chefdk/0.19.6/ubuntu/16.04/chefdk_0.19.6-1_amd64.deb
# 	if [ $? -ne 0 ] ; then
# 	    echo "Could not download chefdk. Exiting..."
# 	    exit 4
# 	fi
#         sudo dpkg -i chefdk_0.19.6-1_amd64.deb
#         if [ $? -ne 0 ] ; then	
# 	   echo "Problem installing chefdk. Fix before re-running the script"
#            exit 5
# 	fi
#     fi
# fi

if [ ! -f karamel-${KARAMEL_VERSION}.tgz ] ; then
    wget http://www.karamel.io/sites/default/files/downloads/karamel-${KARAMEL_VERSION}.tgz
    if [ $? -ne 0 ] ; then
        echo "Could not download karamel. Exiting..."
        exit 4
    fi
fi    
tar zxf karamel-${KARAMEL_VERSION}.tgz 
if [ $? -ne 0 ] ; then
    sleep 2
    echo "Problem unzipping karamel. Retrying..."
    rm -f karamel-${KARAMEL_VERSION}.tgz
    wget http://www.karamel.io/sites/default/files/downloads/karamel-${KARAMEL_VERSION}.tgz
    if [ $? -ne 0 ] ; then
        echo "Could not download karamel. Exiting..."
        exit 4
    fi
    tar zxf karamel-${KARAMEL_VERSION}.tgz
    if [ $? -ne 0 ] ; then
	echo "Couldn't extract karamel. Exiting..."
	exit 7
    fi
fi

#if [ ! -f ${yml}.bak ] ; then
    rm -f ${yml} 2>&1 > /dev/null
    wget https://raw.githubusercontent.com/hopshadoop/karamel-chef/master/cluster-defns/${yml}
    if [ $? -ne 0 ] ; then
      echo "Could not download hopsworks cluster definition file ${yml}. Exiting..."
      exit 9
    fi
#    cp -f ${yml} ${yml}.bak 
#else
#    # If the file is already there, copy the backup over the install version (which may be in an incorrect state)
#    cp -f ${yml}.bak ${yml}
#fi

IP_ADDR="127.0.0.1"

# NET_INTERFACE is set to the first active network interface

if [ "$NET_INTERFACE" == "" ] ; then
  NET_INTERFACE=$(ip -o link show | awk '{print $2,$9}' | grep UP | sed 's/: UP//' | sed 's/\n.*//')
fi    

if [ "$NET_INTERFACE" == "" ] ; then
    echo "Error."
    echo "Could not find an active network interface to install with."
    echo "Is your network up?"
    exit 12
fi   

echo "Using NET_INTERFACE: $NET_INTERFACE"

targetDir=$(printf "%q" $PWD)

echo "Install directory is $targetDir"

owner=$(ls -ld . | awk '{print $3}')

if [ "$owner" != "$USERNAME" ] ; then
    echo "You are not owner of $PWD. Change owner from $owner to $USERNAME"
    exit 12
fi    

perl -pi -e "s/REPLACE_USERNAME/${USERNAME}/g" ${yml}
if [ $? -ne 0 ] ; then
    echo "Error. Couldn't edit the YML file to insert the username."
    echo "Exiting..."
    exit 1
fi

myhostname=`hostname`
host_ip=$(getent hosts $myhostname | awk '{ print $1 }')

perl -pi -e "s/REPLACE_HOSTNAME/${host_ip}/g" ${yml}
if [ $? -ne 0 ] ; then
    echo "Error. Couldn't edit the YML file to insert the username."
    echo "Exiting..."
    exit 1
fi

perl -pi -e "s/REPLACE_NET_IF/${NET_INTERFACE}/g" ${yml}
if [ $? -ne 0 ] ; then
    echo "Error. Couldn't edit the YML file to insert the network interface."
    echo "Exiting..."
    exit 1
fi    
perl -pi -e "s#REPLACE_INSTALL_DIRECTORY#${targetDir}#g" ${yml}
if [ $? -ne 0 ] ; then
    echo "Error. Couldn't edit the YML file to insert the install directory."
    echo "Exiting..."
    exit 1
fi    
perl -pi -e "s/REPLACE_GPU/${use_gpu}/g" ${yml}
if [ $? -ne 0 ] ; then
    echo "Error. Couldn't edit the YML file to insert the use_gpu decision."
    echo "Exiting..."
    exit 1
fi    
perl -pi -e "s/REPLACE_ENABLED_SERVICES/${enable_services}/g" ${yml}
if [ $? -ne 0 ] ; then
    echo "Error. Couldn't edit the YML file to insert the use_gpu decision."
    echo "Exiting..."
    exit 1
fi    


echo "Installing:\n $(cat ${yml})"

# 5. Launch the cluster


cd karamel-${KARAMEL_VERSION}
if [ $? -ne 0 ] ; then
    echo "Couldn't change directory to karamel-${KARAMEL_VERSION}"
    exit 2
fi

echo "Launching Karamel to start the cluster."
echo "You can track progress by opening your browser at: http://localhost:9090/index.html#"
echo "Click on the 'Terminal->status' window to see the progress"
./bin/karamel -headless -launch ../${yml} -server conf/dropwizard.yml $SUDO_PWD

if [ $? -ne 0 ] ; then
    echo "Problem installing with Karamel. Try re-running the installer script."
    exit 10
fi    


if [ $NON_INTERACT -eq 0 ] ; then
    google-chrome -new-tab http://127.0.0.1:8080/hopsworks
fi

echo "To start Hopsworks, open your browser at: http://127.0.0.1:8080/hopsworks"

cd ..

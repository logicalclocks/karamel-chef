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


yml=8GB.yml
NON_INTERACT=0
HOPSWORKS_INSTALLER_VERSION="Hopsworks Localhost Installer Version 0.1 \n\nCopyright (c) Logical Clocks, 2017."
PARAM_INSTALL_DIR=0
PARAM_CLEAN_INSTALL_DIR=0
SCRIPTNAME=`basename $0`

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
# Introduction Splash Screen
#######################################################################

splash_screen() 
{
  clear
  echo "" 
  echo "Hopsworks Installer, Copyright(C) 2017 Logical Clocks AB. All rights reserved."
  echo ""
  echo "This program installs the Hopsworks platform."
  echo ""
  echo "~4.5GB will be downloaded - make sure you have the bandwidth for this."  
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
  echo "You will also need to download a database.."
  echo ""      
  echo "MySQL Server and NDB Storage Engine (MySQL Cluster), Copyright(C) Oracle, GPL v2 licensed."
  echo "By clicking enter, you indicated that you want to download GPL v2 licensed MySQL Cluster."
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
  echo "Copyright(C) 2017 Logical Clocks. All rights reserved." 
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
	      USERNAME=$1
	      ;;
    -ni|--non-interactive)
	      NON_INTERACT=1
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
  display_license
  accept_license  
  clear_screen
fi


pushd .
# 1. setup ssh to localhost to sudo account

if [ ! -f ${HOME}/.ssh/id_rsa.pub ] ; then
   echo "No ssh key found, generating one with ssh-keygen"
   ssh-keygen -b 2048 -f ${HOME}/.ssh/id_rsa -t rsa -q -N ''
fi

public_key=`cat ${HOME}/.ssh/id_rsa.pub`

grep $public_key ${HOME}/.ssh/authorized_keys
keychange=$?

if [ $keychange -ne 0 ] ; then
    echo "Enabling ssh into localhost (needed by Karamel)"
    echo "Adding public key to ${HOME}/.ssh/authorized_keys"
    cat ${HOME}/.ssh/id_rsa.pub >> ${HOME}/.ssh/authorized_keys
fi

# 2. check if openssh server installed

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${USER}localhost "echo 'hello'"

if [ $? -ne 0 ] ; then
    echo "Ssh server needs to be running on localhost. Starting one..."
    sudo service ssh start
    if [ $? -ne 0 ] ; then
	echo "Installing ssh server."
	sudo apt-get install openssh-server -y
	sleep 2
        sudo service ssh status
        if [ $? -ne 0 ] ; then
	    echo "Could not install/start a ssh server. Install openssh-server (or some other ssh server) and re-run installer."
	    exit 2
	fi
    fi
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${USER}@localhost "echo 'hello'"
    if [ $? -ne 0 ] ; then    
      echo "Could not install/start a ssh server. Install openssh-server (or some other ssh server) and re-run installer."
      exit 3
    fi
fi    

java -version | grep '1.8'
if [ $? -ne 0 ] ; then
    echo "No java version 8 found. Installing..."
    sudo apt-get install openjdk-8-jre -y
fi

# 3. Download chefdk, karamel, and cluster.xml
mkdir karamel
cd karamel
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

if [ ! -f karamel-0.3.tgz ] ; then
    wget http://www.karamel.io/sites/default/files/downloads/karamel-0.3.tgz
    if [ $? -ne 0 ] ; then
        echo "Could not download karamel. Exiting..."
        exit 4
    fi
fi    
tar zxf karamel-0.3.tgz
if [ $? -ne 0 ] ; then
    rm -f karamel-0.3.tgz
    wget http://www.karamel.io/sites/default/files/downloads/karamel-0.3.tgz
    if [ $? -ne 0 ] ; then
        echo "Could not download karamel. Exiting..."
        exit 4
    fi
    tar zxf karamel-0.3.tgz    
    if [ $? -ne 0 ] ; then
	echo "Couldn't extract karamel. Exiting..."
	exit 7
    fi
fi
rm -f $yml
wget http://snurran.sics.se/hops/${yml}
if [ $? -ne 0 ] ; then
  echo "Could not download hopsworks cluster definition file ${yml}. Exiting..."
  exit 9
fi

IP_ADDR="127.0.0.1"

net_if="lo"

sed -i.bak s/REPLACE_USERNAME/${USER}/g ./${yml}
sed -i.bak s/REPLACE_IP_ADDR/${IP_ADDR}/g ./${yml} 
sed -i.bak s/REPLACE_NET_IF/${net_if}/g ./${yml}

cd karamel-0.3

# 5. Launch the cluster
./bin/karamel -headless -launch ../8GB.yml -server conf/dropwizard.yml

if [ $? -ne 0 ] ; then
    echo "Problem installing with Karamel. Try re-running the installer script."
    exit 10
fi    
#2>&1 > ../hopsworks-installer.log

popd

echo "Cleaning up ssh keys in authorized keys before exiting..."
if [ $keychange -ne 0 ] ; then
  if grep -v $public_key $HOME/.ssh/authorized_keys > $HOME/.ssh/tmp; then
    mv $HOME/.ssh/tmp $HOME/.ssh/authorized_keys
  fi
fi    

google-chrome -new-tab http://127.0.0.1:8080/hopsworks


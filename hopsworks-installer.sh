#!/bin/bash

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

ssh ${USER}localhost "echo 'hello'"

if [ $? -ne 0 ] ; then
    echo "Ssh server needs to be running on localhost. Starting one..."
    sudo service ssh start
    if [ $? -ne 0 ] ; then
	echo "Installing ssh server."
	sudo apt-get install openssh-server
	sleep 2
        sudo service ssh status
        if [ $? -ne 0 ] ; then
	    echo "Could not install/start a ssh server. Install openssh-server (or some other ssh server) and re-run installer."
	    exit 2
	fi
    fi
    ssh ${USER}@localhost "echo 'hello'"
    if [ $? -ne 0 ] ; then    
      echo "Could not install/start a ssh server. Install openssh-server (or some other ssh server) and re-run installer."
      exit 3
    fi
fi    

# 3. Download chefdk, karamel, and cluster.xml
mkdir karamel
cd karamel
echo "Downloading and installing Karamel"

ubuntu='14.04'
chef-solo --help 2>&1 > /dev/null
if [ $? -ne 0 ] ; then
    grep '16.04' /etc/issue
    if [ $? -ne 0 ] ; then
       ubuntu='16.04'
    fi
    grep '16.10' /etc/issue
    if [ $? -ne 0 ] ; then
       ubuntu='16.04'
    fi
    echo "Downloading chefdk for ubuntu version $ubuntu"    

    if [ ! -f chefdk_0.19.6-1_amd64.deb ] ; then
	wget https://packages.chef.io/files/stable/chefdk/0.19.6/ubuntu/16.04/chefdk_0.19.6-1_amd64.deb
	if [ $? -ne 0 ] ; then
	    echo "Could not download chefdk. Exiting..."
	    exit 4
	fi
    fi
    sudo dpkg -i chefdk_0.19.6-1_amd64.deb
    if [ $? -ne 0 ] ; then
	echo "Retrying to download chefdk"
	rm -f chefdk_0.19.6-1_amd64.deb
	wget https://packages.chef.io/files/stable/chefdk/0.19.6/ubuntu/16.04/chefdk_0.19.6-1_amd64.deb
	if [ $? -ne 0 ] ; then
	    echo "Could not download chefdk. Exiting..."
	    exit 4
	fi
        sudo dpkg -i chefdk_0.19.6-1_amd64.deb
        if [ $? -ne 0 ] ; then	
	   echo "Problem installing chefdk. Fix before re-running the script"
           exit 5
	fi
    fi
fi

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
wget http://snurran.sics.se/hops/installer/8GB.yml .
if [ $? -ne 0 ] ; then
  echo "Could not download hopsworks cluster definition file 8GB.yml. Exiting..."
  exit 9
fi

cd karamel-0.3

# 5. Launch the cluster
./bin/karamel -headless -launch ../8GB.yml -server conf/dropwizard.yml 2>&1 > ../hopsworks-installer.log

popd

echo "Cleaning up ssh keys in authorized keys before exiting..."
if [ $keychange -ne 0 ] ; then
  if grep -v $public_key $HOME/.ssh/authorized_keys > $HOME/.ssh/tmp; then
    mv $HOME/.ssh/tmp $HOME/.ssh/authorized_keys
  fi
fi    

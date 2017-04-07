#!/bin/bash

function help() {
  echo "Usage: ./run.sh [centos|ubuntu] [1|3] [ndb|hopsworks] [random-ports]"
  echo ""
  echo "For example, for a 3-node hopsworks cluster on centos with random ports, run:"
  echo "./run.sh centos 3 hopsworks random-ports"
  exit 1
}

port=
forwarded_port=
echo "Forwarded ports" > .forwarded_ports

function replace_port() {
    p=`shuf -i 2000-65000 -n 1`
    # If the port is already in the file, try again
    grep $p Vagrantfile
    r1=$?
    $(netstat -lptn | grep $p 2>&1 > /dev/null)
    r2=$?
    if [ $r1 -eq 0 ] || [ $r2 -eq 0 ] ; then
       p=`shuf -i 2000-65000 -n 1`	
    fi
    
    perl -pi -e "s/$port/$p/g" Vagrantfile
    perl -pi -e "s/$p/$port/" Vagrantfile    
#   perl -pi -e "s/(($port).*?){2}\2/\1\1$p" Vagrantfile
    echo "$forwarded_port -> $p" >> .forwarded_ports
}    

if [ $# -lt 3 ] ; then
    help
fi

PORTS=0

if [ $# -eq 4 ] ; then
    if [ $4 != "random-ports" ] ; then
       help	   
    fi
    PORTS=1	 
fi    

#set -e

if [ ! -f Vagrantfile.$1.$2 ] ; then
 echo "Couldn't find the Vagrantfile.$1.$2 for your cluster"
 exit 1
fi
if [ ! -f cluster.yml.$2.$3 ] ; then
 echo "Couldn't find the cluster.yml.$1.$2 for your cluster"
 exit 1
fi
 
cp Vagrantfile.$1.$2 Vagrantfile
cp cluster.yml.$2.$3 cluster.yml


if [ $PORTS -eq 1 ] ; then

    SAVEIFS=$IFS
    # Change IFS to new line.
    IFS=$'\n'
    ports=$(grep forward Vagrantfile | grep -Eo '[0-9]{2,5}'|xargs)
    ports=($ports)
    echo "Found forwarded Ports: $ports"
    # Restore IFS
    IFS=$SAVEIFS
    count=0

    for i in $ports ; do
	odd=$(($count % 2))
	if [ $odd -eq 1 ] ; then
	    port=$i
	    replace_port
	else
	    forwarded_port=$i
	fi
	count=$(($count + 1))
    done
    exit 1
fi    

echo "Removing old vendored cookbooks"
rm -rf cookbooks > /dev/null 2>&1
rm -f Berksfile.lock nohup.out > /dev/null 2>&1
echo "Vendoring cookbooks using 'berks vendor cookbooks'"
berks vendor cookbooks

echo "Running the Vagrantfile using 'vagrant up'"
nohup vagrant up &

cat .forwarded_ports

exit 0

#!/bin/bash

function help() {
  echo "Usage: ./run.sh [centos|ubuntu|ports] [1|3] [ndb|hopsworks|hops] [no-random-ports]"
  echo ""
  echo "For example, for a 3-node hopsworks cluster on centos with random ports, run:"
  echo "./run.sh centos 3 hopsworks"
  echo "To find out the currently mapped ports, run:"
  echo "./run.sh ports"
  exit 1
}

port=
forwarded_port=
ports=

function replace_port() {
    res=0
    p=
    while [ $res -eq 0 ] ; do 
	p=`shuf -i 20000-65000 -n 1`
	# If the port is already in the file, try again
	grep $p Vagrantfile
	r1=$?
	$(netstat -lptn | grep $p 2>&1 > /dev/null)
	r2=$?
	if [ $r1 -eq 0 ] || [ $r2 -eq 0 ] ; then
	    p=`shuf -i 2000-65000 -n 1`
	else
	    res=1
	fi
    done

    if [ "$forwarded_port" != "22" ] ; then
      perl -pi -e "s/$forwarded_port/$p/g" Vagrantfile
      perl -pi -e "s/$p/$forwarded_port/" Vagrantfile
      echo "$port -> $p"
    else 
       echo "New port is: $p"
       sed "0,/RE/s/10022/$p/" Vagrantfile > Vagrantfile.new
       sed "0,/RE/s/10023/$(expr $p + 1)/" Vagrantfile.new > Vagrantfile
       sed "0,/RE/s/10024/$(expr $p + 2)/" Vagrantfile > Vagrantfile.new
       mv Vagrantfile.new Vagrantfile
    fi
}    

function parse_ports() {
    SAVEIFS=$IFS
    # Change IFS to new line.
    IFS=$'\n'
    ports=$(grep forward Vagrantfile | grep -Eo '[0-9]{2,5}'|xargs)
    count=0
    echo "Found forwarded Ports:"
    ports=($ports)
    # Restore IFS
    IFS=$SAVEIFS
    for i in $ports ; do
	odd=$(($count % 2))
	if [ $odd -eq 1 ] ; then
           echo "$i"
	else
           echo -n "$i -> "
	fi
	count=$(($count + 1))
    done
}


if [ $1 == "ports" ] ; then
 parse_ports
 exit 0
fi

if [ $# -lt 3 ] ; then
    help
fi

PORTS=1

if [ $# -eq 4 ] ; then
    if [ $4 != "no-random-ports" ] ; then
       help	   
    fi
    PORTS=0	 
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

    parse_ports
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

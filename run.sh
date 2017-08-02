#!/bin/bash

function help() {
  echo "Usage: ./run.sh [centos|ubuntu|ports] [1|3] [ndb|hopsworks|hops|jim|antonios|theofilos|etc] [no-random-ports]"
  echo ""
  echo "Create your own cluster definition from an existing one:"
  echo "cp cluster.1.hopsworks cluster.1.jim"
  echo "For example, for a 1-node hopsworks cluster on ubuntu for development with random ports, run:"
  echo "./run.sh ubuntu 1 jim"
  echo "To find out the currently mapped ports, run:"
  echo "./run.sh ports"
  exit 1
}

port=
forwarded_port=
ports=
http_port=8080

VBOX_MANAGE=/usr/bin/VBoxManage
OCTETS="192.168."
ORIGINAL_OCTETS=${OCTETS}"56"

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
      if [ "$forwarded_port" == "8080" ] ; then
         perl -pi -e "s/$forwarded_port/$p/" cluster.yml
         perl -pi -e "s/$forwarded_port/$p/g" Vagrantfile
	 http_port=$p
      fi
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

function change_subnet() {
    priv_subnets=($($VBOX_MANAGE list hostonlyifs | grep "IPAddress:" | awk -F' ' '{print $2}' | awk -F'.' '{print $3}'))
    
    if [ ${#priv_subnets[@]} -gt 0 ]; then
	SAVEIFS=$IFS
	IFS=$'\n'
	sorted=($(sort <<<"${priv_subnets[*]}"))
	IFS=$SAVEIFS
	new_subnet=$((${sorted[-1]} + 1))
	new_octets=${OCTETS}${new_subnet}
	sed -i "s/${ORIGINAL_OCTETS}/${new_octets}/g" Vagrantfile
	sed -i "s/${ORIGINAL_OCTETS}/${new_octets}/g" cluster.yml
    fi
}

if [ "$1" == "ports" ] ; then
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

if [ ! -f vagrantfiles/Vagrantfile.$1.$2 ] ; then
 echo "Couldn't find the Vagrantfile.$1.$2 for your cluster in the vagrantfiles directory"
 exit 1
fi
if [ ! -f cluster-defns/cluster.yml.$2.$3 ] ; then
 echo "Couldn't find the cluster.yml.$1.$2 for your cluster in the cluster-defns directory"
 exit 1
fi
 
cp vagrantfiles/Vagrantfile.$1.$2 Vagrantfile
cp cluster-defns/cluster.yml.$2.$3 cluster.yml


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

if [ $2 -gt 1 ]; then
    echo "Changing VMs subnet"
    change_subnet
fi

echo "Removing old vendored cookbooks"
rm -rf cookbooks > /dev/null 2>&1
rm -f Berksfile.lock nohup.out > /dev/null 2>&1
echo "Vendoring cookbooks using 'berks vendor cookbooks'"
berks vendor cookbooks

echo "Running the Vagrantfile using 'vagrant up'"
nohup vagrant up &

parse_ports

echo ""
echo "Connect your browser to: http://$(hostname):${http_port}/hopsworks"
echo ""
exit 0

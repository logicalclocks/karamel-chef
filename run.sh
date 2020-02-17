#!/bin/bash

function help() {
  echo "Usage: ./run.sh [centos|ubuntu|ports|demodela] [1|3] [ndb|hopsworks|hops|jim|antonios|theofilos|demodela|etc] [no-random-ports] [udp-hack]"
  echo ""
  echo "Create your own cluster definition from an existing one:"
  echo "cp cluster.1.hopsworks cluster.1.jim"
  echo "For example, for a 1-node hopsworks cluster on ubuntu for development with random ports, run:"
  echo "./run.sh ubuntu 1 jim"
  echo "For centos without random ports, run:"
  echo "./run.sh centos 1 centos no-random-ports"
  echo "To find out the currently mapped ports, run:"
  echo "./run.sh ports"
  exit 1
}

port=
forwarded_port=
ports=
#http_port=8080

VBOX_MANAGE=/usr/bin/VBoxManage
OCTETS="192.168."
ORIGINAL_OCTETS=${OCTETS}"56"

GB=1024
SOFT_LIMIT=$(( 80 * GB ))
HARD_LIMIT=$(( 30 * GB ))

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function check_available_disk_space() {
    available_mb_str=$(df . --output=avail -B MB | grep -v "\W")
    available_mb=${available_mb_str//[^0-9]*/}
    echo "Available MB on device: $available_mb_str HARD limit : ${HARD_LIMIT}MB SOFT limit: ${SOFT_LIMIT}MB"
    if [ $available_mb -le $HARD_LIMIT ]
    then
        echo -e "${RED}*****************************************************${NC}"
        echo -e "${RED}*                                                   *${NC}"
        echo -e "${RED}*   Error: Not enough disk space left on device :(  *${NC}"
        echo -e "${RED}*                                                   *${NC}"
        echo -e "${RED}*****************************************************${NC}"
	exit 3
    elif [ $available_mb -le $SOFT_LIMIT ]
    then
        echo -e "${YELLOW}**************************************************************${NC}"
        echo -e "${YELLOW}*                                                            *${NC}"
        echo -e "${YELLOW}*   Warning: Available disk space on device is getting low   *${NC}"
        echo -e "${YELLOW}*                                                            *${NC}"
        echo -e "${YELLOW}**************************************************************${NC}"
	sleep 2
    fi
}

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
      if [ "$forwarded_port" == "42011" ] ; then
        echo "dela port 42011 - leave it alone"
	    elif [ "$forwarded_port" == "42012" ] ; then
        echo "dela port 42012 - leave it alone"
	    elif [ "$forwarded_port" == "42013" ] ; then
        echo "dela port 42013 - leave it alone"
#       if [ "$forwarded_port" == "9090" ] ; then
#          echo "9090 - leave it alone"
#      else if [ "$forwarded_port" == "8080" ] ; then
#         perl -pi -e "s/$forwarded_port/$p/g" Vagrantfile
#         perl -pi -e "s/$forwarded_port/$p/" cluster.yml
#      	 http_port=$p
#         echo "http_port -> $p"
      else
        perl -pi -e "s/$forwarded_port/$p/g" Vagrantfile
        perl -pi -e "s/$p/$forwarded_port/" Vagrantfile
        echo "$port -> $p"
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
    new_subnet=-1
    while [ $new_subnet -eq -1 ]
    do
      tentative=$(($RANDOM % 255))
      present=0
      for i in "${priv_subnets[@]}"
      do
        if [ "$i" == "$tentative" ]; then
          present=1
          break
        fi
      done
      if [ $present -eq 0 ]; then
        new_subnet=$tentative
      fi
    done

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


check_available_disk_space


PORTS=1

if [ $# -eq 4 ] ; then
    if [ $4 != "no-random-ports" ] ; then
       help
    fi
    PORTS=0
fi

UDP_HACK=0
if [ $# -eq 5 ] ; then
    if [ $4 != "no-random-ports" ] ; then
       help
    fi
    PORTS=0
    if [ $5 != "udp-hack" ] ; then
       help
    fi
    UDP_HACK=1
fi

#set -e

if [ ! -f vagrantfiles/Vagrantfile.$1.$2 ] ; then
 echo "Couldn't find the Vagrantfile.$1.$2 for your cluster in the vagrantfiles directory"
 exit 1
fi
if [ ! -f cluster-defns/$2.$3.yml ] ; then
 echo "Couldn't find the $2.$3.yml for your cluster in the cluster-defns directory"
 exit 1
fi

cp vagrantfiles/Vagrantfile.$1.$2 Vagrantfile
cp cluster-defns/$2.$3.yml cluster.yml


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
if [ $? -ne 0 ] ; then
  echo "ERROR: 'berks vendor cookbooks' failed"
  exit 3
fi
echo "Running the Vagrantfile using 'vagrant up'"
nohup vagrant up &

if [ $UDP_HACK -eq 1 ]; then
    ./udp_hacky_fix.sh
fi

parse_ports

echo ""
echo "Connect your browser to: http://$(hostname):${http_port}/hopsworks"
echo ""
exit 0

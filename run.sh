#!/bin/bash

function help() {
  echo "Usage: ./run.sh [centos|ubuntu|ports|ssh-config|deploy-ear] [1|3] [ndb|hopsworks|hops|jim|antonios||etc] [no-random-ports] [udp-hack]"
  echo ""
  echo "Create a custom cluster definition from an existing one:"
  echo "cp cluster-defns/1.hopsworks.yml cluster-defns/1.jim.yml"
  echo ""
  echo "For a hopsworks cluster on ubuntu or centos, run:"
  echo "./run.sh ubuntu 1 jim"
  echo "./run.sh centos 1 centos"
  exit 1
}

port=
forwarded_port=
ports=


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
       sed "0,/10022/s/10022/$p/" Vagrantfile > Vagrantfile.new
       sed "0,/10023/s/10023/$(expr $p + 1)/" Vagrantfile.new > Vagrantfile
       sed "0,/10024/s/10024/$(expr $p + 2)/" Vagrantfile > Vagrantfile.new
       mv Vagrantfile.new Vagrantfile
    fi
}

function parse_ports() {
    SAVEIFS=$IFS
    # Change IFS to new line.
    IFS=$'\n'
    ports=$(grep forward Vagrantfile | grep -Eo '[0-9]{2,5}'|xargs)
    count=0
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

function deploy_ear() {

    if [ -f ${HOME}/.ssh/id_rsa.pub ] ; then
	ssh_key=$(cat ${HOME}/.ssh/id_rsa.pub)

	grep "$ssh_key" ~/.ssh/authorized_keys >/dev/null 2>&1
	if [ $? -ne 0 ] ; then
          cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	fi
    else
	echo "----------------------------------------------------------"
	echo "WARNING: the deploy-ear.sh script will not work as you do not have a public-private key"
	echo "Creating a public/private ssh key with no password with this command:"
	echo "cat /dev/zero | ssh-keygen -m PEM -q -N > /dev/null "
	echo "----------------------------------------------------------"
	cat /dev/zero | ssh-keygen -m PEM -q -N > /dev/null
    fi
    echo ""
    echo ""
    echo "You can redeploy your ear on Vagrant after you follow these instructions: "
    echo "On dev4.hops.works:"
    echo ""
    echo "mkdir Projects"
    echo "cd Projects"
    echo "# Change this from jimdowling to your private github repo"
    echo "git clone git@github.com:jimdowling/hopsworks-ee.git"
    echo "cd Projects/hopsworks-ee"
    echo "./scripts/allow-cors.sh"
    echo "mvn clean install -Pkube,web,jupyter-git -DskipTests"
    echo ""
    echo "cd ~/karamel-chef"
    echo "vagrant ssh"
    echo "#now on vagrant, copies the hopsworks-ear.ear file from dev4, and deploys it to glassfish"
    echo "./deploy-ear.sh"
    echo ""
}


function ssh_config() {
    echo "=========================================="
    echo ""
    echo "Copy and paste the following into ~/.ssh/config"
    echo "Make sure permissions are correct:"
    echo "chmod 600 ~/.ssh/config"
    echo ""
    echo "=========================================="
    echo ""
    echo ""    
    echo "Host dev4"
    echo "  Hostname dev4.hops.works"
    echo "  User $USER"
    echo "Host vagrant"
    echo "  Hostname dev4.hops.works"
    echo "  User $USER"
    echo "  ProxyJump dev4"
    DEBUG_PORT=0
    HTTPS_PORT=0
    GLASSFISH_PORT=0
    KARAMEL_PORT=0
    SSH_PORT=0

    
    SAVEIFS=$IFS
    # Change IFS to new line.
    IFS=$'\n'
    ports=$(grep forward Vagrantfile | grep -Eo '[0-9]{2,5}'|xargs)
    count=0
    ports=($ports)
    # Restore IFS
    IFS=$SAVEIFS
    for i in $ports ; do
	
	odd=$(($count % 2))
	if [ $odd -eq 1 ] ; then
	    if [ $DEBUG_PORT -eq 9009 ] ; then
	      DEBUG_PORT=$i	
	    fi
	    if [ $HTTPS_PORT -eq 8181 ] ; then
	      HTTPS_PORT=$i	
	    fi
	    if [ $GLASSFISH_PORT -eq 4848 ] ; then
	      GLASSFISH_PORT=$i	
	    fi
	    if [ $KARAMEL_PORT -eq 9090 ] ; then
	      KARAMEL_PORT=$i	
	    fi
	    if [ $SSH_PORT -eq 22 ] ; then
	      SSH_PORT=$i	
	    fi
	else
	    if [ $i -eq 9009 ] ; then
		DEBUG_PORT=9009
	    fi
	    if [ $i -eq 8181 ] ; then
		HTTPS_PORT=8181
	    fi
	    if [ $i -eq 4848 ] ; then
		GLASSFISH_PORT=4848
	    fi
	    if [ $i -eq 9090 ] ; then
		KARAMEL_PORT=9090
	    fi
	    if [ $i -eq 22 ] ; then
		SSH_PORT=22
	    fi
	fi
	count=$(($count + 1))
    done

    echo "  LocalForward 9009 localhost:$DEBUG_PORT"
    echo "  LocalForward 8181 localhost:$HTTPS_PORT"
    echo "  LocalForward 4848 localhost:$GLASSFISH_PORT"
    echo "  LocalForward 9090 localhost:$KARAMEL_PORT"
    echo ""    
    echo "Host dev4_vagrant"
    echo "  HostName dev4.hops.works"
    echo "  ProxyJump dev4"
    echo "  User vagrant"
    echo "  Port $SSH_PORT"
    echo "  IdentityFile ~/.vagrant.d/insecure_private_key" 
    echo ""    
    echo ""    
    
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

if [ "$1" == "ssh-config" ] ; then
 ssh_config
 exit 0
fi

if [ "$1" == "deploy-ear" ] ; then
 deploy_ear
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

cp -f scripts/deploy-ear.sh .deploy.sh
sed -i "s/__USER__/$USER/g" .deploy.sh

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
deploy_ear
ssh_config

exit 0

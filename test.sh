#!/bin/bash

port=
forwarded_port=
ports=
#http_port=8080

VBOX_MANAGE=/usr/bin/VBoxManage
OCTETS="172.24."
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

PORTS=1

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

change_subnet

echo "Removing old vendored cookbooks"
rm -rf cookbooks > /dev/null 2>&1
rm -f Berksfile.lock > /dev/null 2>&1
echo "Vendoring cookbooks using 'berks vendor cookbooks'"
berks vendor cookbooks

echo "Running the Vagrantfile using 'vagrant up'"
vagrant up

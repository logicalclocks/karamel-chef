#!/bin/bash

if [ $# -ne 1 ] ; then
  echo "Usage: ./run.sh [centos|ubuntu]"
  echo ""
  exit 1
fi

if [ "$1" == "centos" ] ; then
 cp Vagrantfile.centos Vagrantfile
elif [ "$1" == "ubuntu" ] ; then
 cp Vagrantfile.ubuntu Vagrantfile
else
  echo "Usage: ./run.sh [centos|ubuntu]"
  echo ""
  exit 1
fi

set -e
echo "Removing old vendored cookbooks"
rm -rf cookbooks > /dev/null 2>&1
rm -f Berksfile.lock nohup.out > /dev/null 2>&1
echo "Vendoring cookbooks using 'berks vendor cookbooks'"
berks vendor cookbooks

echo "Running the Vagrantfile using 'vagrant up'"
nohup vagrant up &



#!/bin/bash

if [ $# -ne 3 ] ; then
  echo "Usage: ./run.sh [centos|ubuntu] [1|3] [ndb|hopsworks]"
  echo ""
  exit 1
fi

set -e

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

echo "Removing old vendored cookbooks"
rm -rf cookbooks > /dev/null 2>&1
rm -f Berksfile.lock nohup.out > /dev/null 2>&1
echo "Vendoring cookbooks using 'berks vendor cookbooks'"
berks vendor cookbooks

echo "Running the Vagrantfile using 'vagrant up'"
nohup vagrant up &



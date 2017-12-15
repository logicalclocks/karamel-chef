#!/bin/bash

. dela_env.sh
. dela_ports.sh

materialize() 
{
  FILE=$1
  TEMPLATE=$2
  VALUES=$3
  echo "$FILE materializing"
  rm -f $FILE
  cp $TEMPLATE $FILE
  for val in $VALUES
  do 
    echo "$val = ${!val}"
    sed -i -e "s/{$val}/${!val}/g" $FILE
  done
  echo "$FILE materialized"
}

if [ $CLUSTER_OS == "ubuntu" ] ; then
  OS_VERSION="config.vm.box = \"bento\/ubuntu-16.04\"\\n  config.vm.box_version = \"2.3.5\""
elif [ $CLUSTER_OS == "centos" ]; then
  OS_VERSION="config.vm.box = \"bento/centos-7.2\""
fi
if [ $CLUSTER_OS == "ubuntu" ] ; then
  NETWORK_INTERFACE="enp0s3"
elif [ $CLUSTER_OS == "centos" ]; then
  NETWORK_INTERFACE="eth0"
fi
if [ $CLUSTER_MULTI_USER == true ] ; then
  USER_SETTING=""
else
  USER_SETTING="user: vagrant"
fi
VALUES=("OS_VERSION" "SSH_P" "MYSQL_P" "KARAMEL_P" "WEB_P" "DEBUG_P" "GFISH_P" "DELA1_P" "DELA2_P" "DELA3_P" "DELA4_P" "PORT1" "PORT2" "PORT3" "PORT4" "PORT5" "PORT6" "PORT7" "PORT8" "PORT9")
materialize "../vagrantfiles/Vagrantfile.dela.1" "../vagrantfiles/Vagrantfile.dela_template.1" $VALUES
VALUES=("GITHUB" "BRANCH" "NETWORK_INTERFACE" "USER_SETTING" "WEB_P" "DELA1_P" "DELA2_P" "DELA3_P" "DELA4_P" "HS_WEB1_P" "HS_WEB2_P" "CLUSTER_MANUAL_REGISTER" "HOPSSITE_DOMAIN" "CLUSTER_EMAIL" "SOURCE_CODE" "CLUSTER_ORG" "CLUSTER_UNIT" "HOPSSITE_PASSWORD")
materialize "../cluster-defns/1.dela.yml" "../cluster-defns/1.dela_template.yml" $VALUES
VALUES=("CLUSTER_EMAIL" "CLUSTER_PASSWORD" "CLUSTER_ORG" "CLUSTER_UNIT" "HOPSSITE_DOMAIN" "HS_WEB1_P")
materialize "dela_register.sh" "dela_register_template.sh" $VALUES
chmod +x dela_register.sh
VALUES=("CLUSTER_DOMAIN" "DELA1_P" "DELA2_P" "DELA3_P")
materialize "udp_hacky_fix.sh" "udp_hacky_fix_template.sh" $VALUES
chmod +x udp_hacky_fix.sh

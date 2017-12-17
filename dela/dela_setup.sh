#!/bin/bash
set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi

KCHEF_DIR=${PWD}
. ${KCHEF_DIR}/dela/running/dela_env.sh
. ${KCHEF_DIR}/dela/running/dela_ports.sh

materialize() 
{
  FILE=$1
  TEMPLATE=$2
  VALUES=$3
  echo "$FILE materializing"
  rm -f $FILE
  cp $TEMPLATE $FILE
  for val in ${VALUES[@]}
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
declare -a VALUES=("OS_VERSION" "SSH_P" "MYSQL_P" "KARAMEL_P" "WEB_P" "DEBUG_P" "GFISH_P" "DELA1_P" "DELA2_P" "DELA3_P" "DELA4_P" "PORT1" "PORT2" "PORT3" "PORT4" "PORT5" "PORT6" "PORT7" "PORT8" "PORT9")
materialize "${KCHEF_DIR}/vagrantfiles/Vagrantfile.dela.1" "${KCHEF_DIR}/dela/templates/Vagrantfile.dela_template.1" $VALUES
declare -a VALUES=("GITHUB" "BRANCH" "NETWORK_INTERFACE" "USER_SETTING" "WEB_P" "DELA1_P" "DELA2_P" "DELA3_P" "DELA4_P" "HS_WEB1_P" "HS_WEB2_P" "CLUSTER_MANUAL_REGISTER" "HOPSSITE_DOMAIN" "CLUSTER_EMAIL" "SOURCE_CODE" "CLUSTER_ORG" "CLUSTER_UNIT" "CLUSTER_PASSWORD")
materialize "${KCHEF_DIR}/cluster-defns/1.dela.yml" "${KCHEF_DIR}/dela/templates/1.dela_template.yml" $VALUES
declare -a VALUES=("CLUSTER_EMAIL" "CLUSTER_PASSWORD" "CLUSTER_ORG" "CLUSTER_UNIT" "HOPSSITE_DOMAIN" "HS_WEB1_P")
materialize "${KCHEF_DIR}/dela/running/register.sh" "${KCHEF_DIR}/dela/templates/register_template.sh" $VALUES
chmod +x ${KCHEF_DIR}/dela/running/register.sh
declare -a VALUES=("CLUSTER_DOMAIN" "DELA1_P" "DELA2_P" "DELA3_P")
materialize "${KCHEF_DIR}/dela/running/udp_hacky_fix.sh" "${KCHEF_DIR}/dela/templates/udp_hacky_fix_template.sh" $VALUES
chmod +x ${KCHEF_DIR}/dela/running/udp_hacky_fix.sh

#!/bin/bash

. dela_env.sh
. dela_ports.sh

##VAGRANTFILE
rm -f ../vagrantfiles/Vagrantfile.dela.1
cp ../vagrantfiles/Vagrantfile.dela_template.1 ../vagrantfiles/Vagrantfile.dela.1
if [ $CLUSTER_OS == "ubuntu" ] ; then
  OS_VERSION="config.vm.box = \"bento\/ubuntu-16.04\"\\n  config.vm.box_version = \"2.3.5\""
elif [ $CLUSTER_OS == "centos" ]; then
  OS_VERSION="config.vm.box = \"bento/centos-7.2\""
fi
sed -i -e "s/{OS_VERSION}/${OS_VERSION}/g" ../vagrantfiles/Vagrantfile.dela.1

#basic hopsworks ports
sed -i -e "s/{SSH_P}/${SSH_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{MYSQL_P}/${MYSQL_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{KARAMEL_P}/${KARAMEL_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{WEB_P}/${WEB_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{DEBUG_P}/${DEBUG_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{GFISH_P}/${GFISH_P}/g" ../vagrantfiles/Vagrantfile.dela.1
for i in {1..9}
do 
  PORT=$((PORT${i}))
  sed -i -e "s/{PORT${i}}/${PORT}/g" ../vagrantfiles/Vagrantfile.dela.1
done
#dela ports
sed -i -e "s/{DELA1_P}/${DELA1_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{DELA2_P}/${DELA2_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{DELA3_P}/${DELA3_P}/g" ../vagrantfiles/Vagrantfile.dela.1
sed -i -e "s/{DELA4_P}/${DELA4_P}/g" ../vagrantfiles/Vagrantfile.dela.1
#CLUSTER_DEF
rm -f ../cluster-defns/1.dela.yml
cp ../cluster-defns/1.dela_template.yml ../cluster-defns/1.dela.yml

sed -i -e "s/{github}/${GITHUB}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{branch}/${BRANCH}/g" ../cluster-defns/1.dela.yml
if [ $CLUSTER_OS == "ubuntu" ] ; then
  NETWORK_INTERFACE="enp0s3"
elif [ $CLUSTER_OS == "centos" ]; then
  NETWORK_INTERFACE="eth0"
fi
sed -i -e "s/{NETWORK_INTERFACE}/${NETWORK_INTERFACE}/g" ../cluster-defns/1.dela.yml

if [ $CLUSTER_MULTI_USER == true ] ; then
  USER_SETTING=""
else
  USER_SETTING="user: vagrant"
fi
sed -i -e "s/{USER_SETTING}/${USER_SETTING}/g" ../cluster-defns/1.dela.yml
#basic ports
sed -i -e "s/{WEB_P}/${WEB_P}/g" ../cluster-defns/1.dela.yml
#dela ports
sed -i -e "s/{DELA1_P}/${DELA1_P}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{DELA2_P}/${DELA2_P}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{DELA3_P}/${DELA3_P}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{DELA4_P}/${DELA4_P}/g" ../cluster-defns/1.dela.yml
#hopssite ports
sed -i -e "s/{HS_WEB1_P}/${HS_WEB1_P}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{HS_WEB2_P}/${HS_WEB2_P}/g" ../cluster-defns/1.dela.yml
#
sed -i -e "s/{CLUSTER_MANUAL_REGISTER}/${CLUSTER_MANUAL_REGISTER}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{hsdomain}/${HOPSSITE_DOMAIN}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{hsemail}/${CLUSTER_EMAIL}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{sourcecode}/${SOURCE_CODE}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{CLUSTER_ORG}/${CLUSTER_ORG}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{CLUSTER_UNIT}/${CLUSTER_UNIT}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{hspassword}/${HOPSSITE_PASSWORD}/g" ../cluster-defns/1.dela.yml
#*******
rm -f dela_udp_hacky_fix.sh
cp udp_hacky_fix_template.sh dela_udp_hacky_fix.sh
chmod +x dela_udp_hacky_fix.sh

sed -i -e "s/{cluster_domain}/${CLUSTER_DOMAIN}/g" dela_udp_hacky_fix.sh
#dela ports
sed -i -e "s/{DELA1_P}/${DELA1_P}/g" dela_udp_hacky_fix.sh
sed -i -e "s/{DELA2_P}/${DELA2_P}/g" dela_udp_hacky_fix.sh
sed -i -e "s/{DELA3_P}/${DELA3_P}/g" dela_udp_hacky_fix.sh
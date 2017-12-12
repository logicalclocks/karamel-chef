#!/bin/bash

. dela_env.sh
. dela_ports.sh

rm -f ../vagrantfiles/Vagrantfile.dela.1
cp ../vagrantfiles/Vagrantfile.dela_template.1 ../vagrantfiles/Vagrantfile.dela.1
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
#*******
rm -f ../cluster-defns/1.dela.yml
cp ../cluster-defns/1.dela_template.yml ../cluster-defns/1.dela.yml

sed -i -e "s/{github}/${GITHUB}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{branch}/${BRANCH}/g" ../cluster-defns/1.dela.yml

#basic ports
sed -i -e "s/{WEB_P}/${WEB_P}/g" ../cluster-defns/1.dela.yml
#dela ports
sed -i -e "s/{DELA1_P}/${DELA1_P}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{DELA2_P}/${DELA2_P}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{DELA3_P}/${DELA3_P}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{DELA4_P}/${DELA4_P}/g" ../cluster-defns/1.dela.yml
#
sed -i -e "s/{network_interface}/${NETWORK_INTERFACE}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{hsdomain}/${CLUSTER_DOMAIN}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{hsemail}/${CLUSTER_EMAIL}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{sourcecode}/${SOURCE_CODE}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{cn}/${CLUSTER_CN}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{company}/${CLUSTER_COMPANY}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{unit}/${CLUSTER_UNIT}/g" ../cluster-defns/1.dela.yml
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
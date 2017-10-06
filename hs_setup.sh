#!/bin/bash

. hs_env.sh

rm -f vagrantfiles/Vagrantfile.hopssite.1
cp vagrantfiles/Vagrantfile.hopssite_template.1 vagrantfiles/Vagrantfile.hopssite.1
#basic hopsworks ports
for i in {1..15}
do 
  PORT=$((20000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{port${i}}/${PORT}/g" vagrantfiles/Vagrantfile.hopssite.1
done
#dela ports
for i in {1..4}
do 
  PORT=$((40000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{delaport${i}}/${PORT}/g" vagrantfiles/Vagrantfile.hopssite.1
done
#hopssite ports
for i in {1..2}
do 
  PORT=$((50000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{hsport${i}}/${PORT}/g" vagrantfiles/Vagrantfile.hopssite.1
done

#*******
rm -f cluster-defns/1.hopssite.yml
cp cluster-defns/1.hopssite_template.yml cluster-defns/1.hopssite.yml

sed -i -e "s/{github}/${GITHUB}/g" cluster-defns/1.hopssite.yml
sed -i -e "s/{branch}/${BRANCH}/g" cluster-defns/1.hopssite.yml

#basic ports
PORT=$((24000 + ${CLUSTER_SUFFIX}))
sed -i -e "s/{port4}/${PORT}/g" cluster-defns/1.hopssite.yml
#dela ports
for i in {1..4}
do 
  PORT=$((40000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{delaport${i}}/${PORT}/g" cluster-defns/1.hopssite.yml
done
#hopssite ports
PORT=$((52000 + ${CLUSTER_SUFFIX}))
sed -i -e "s/{hsport2}/${PORT}/g" cluster-defns/1.hopssite.yml

sed -i -e "s/{hsdomain}/${CLUSTER_DOMAIN}/g" cluster-defns/1.hopssite.yml
sed -i -e "s/{hsemail}/${CLUSTER_EMAIL}/g" cluster-defns/1.hopssite.yml
sed -i -e "s/{sourcecode}/${SOURCE_CODE}/g" cluster-defns/1.hopssite.yml
sed -i -e "s/{hscompany}/${CLUSTER_COMPANY}/g" cluster-defns/1.hopssite.yml
sed -i -e "s/{hsunit}/${CLUSTER_UNIT}/g" cluster-defns/1.hopssite.yml

#*******
rm -f hs_udp_hacky_fix.sh
cp udp_hacky_fix_template.sh hs_udp_hacky_fix.sh
chmod +x hs_udp_hacky_fix.sh

sed -i -e "s/{cluster_domain}/${CLUSTER_DOMAIN}/g" hs_udp_hacky_fix.sh
#dela ports
for i in {1..4}
do 
  PORT=$((40000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{delaport${i}}/${PORT}/g" hs_udp_hacky_fix.sh
done
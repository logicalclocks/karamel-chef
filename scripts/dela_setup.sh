#!/bin/bash

. dela_env.sh

rm -f ../vagrantfiles/Vagrantfile.dela.1
cp ../vagrantfiles/Vagrantfile.dela_template.1 ../vagrantfiles/Vagrantfile.dela.1
#basic hopsworks ports
for i in {1..15}
do 
  PORT=$((20000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{port${i}}/${PORT}/g" ../vagrantfiles/Vagrantfile.dela.1
done
#dela ports
for i in {1..4}
do 
  PORT=$((40000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{delaport${i}}/${PORT}/g" ../vagrantfiles/Vagrantfile.dela.1
done
#hopssite ports
for i in {1..2}
do 
  PORT=$((50000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{hsport${i}}/${PORT}/g" ../vagrantfiles/Vagrantfile.dela.1
done

#*******
rm -f ../cluster-defns/1.dela.yml
cp ../cluster-defns/1.dela_template.yml ../cluster-defns/1.dela.yml

sed -i -e "s/{github}/${GITHUB}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{branch}/${BRANCH}/g" ../cluster-defns/1.dela.yml

#basic ports
PORT=$((24000 + ${CLUSTER_SUFFIX}))
sed -i -e "s/{port4}/${PORT}/g" ../cluster-defns/1.dela.yml

#dela ports
for i in {1..4}
do 
  PORT=$((40000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{delaport${i}}/${PORT}/g" ../cluster-defns/1.dela.yml
done
#hopssite ports
PORT=$((52000 + ${HOPSSITE_SUFFIX}))
sed -i -e "s/{hsport2}/${PORT}/g" ../cluster-defns/1.dela.yml
PORT=$((24000 + ${HOPSSITE_SUFFIX}))
sed -i -e "s/{hsport4}/${PORT}/g" ../cluster-defns/1.dela.yml

sed -i -e "s/{hsdomain}/${CLUSTER_DOMAIN}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{hsemail}/${CLUSTER_EMAIL}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{sourcecode}/${SOURCE_CODE}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{company}/${CLUSTER_COMPANY}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{unit}/${CLUSTER_UNIT}/g" ../cluster-defns/1.dela.yml
sed -i -e "s/{hspassword}/${HOPSSITE_PASSWORD}/g" ../cluster-defns/1.dela.yml
#*******
rm -f dela_udp_hacky_fix.sh
cp udp_hacky_fix_template.sh dela_udp_hacky_fix.sh
chmod +x dela_udp_hacky_fix.sh

sed -i -e "s/{cluster_domain}/${CLUSTER_DOMAIN}/g" dela_udp_hacky_fix.sh
#dela ports
for i in {1..4}
do 
  PORT=$((40000 + i*1000 + ${CLUSTER_SUFFIX}))
  sed -i -e "s/{delaport${i}}/${PORT}/g" dela_udp_hacky_fix.sh
done
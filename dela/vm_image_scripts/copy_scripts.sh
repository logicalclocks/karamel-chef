#!/bin/bash
set -e
if [ $# -ne 2 ] ; then
  echo "first param - vm ssh forwarder port, type hopssite/bbc5"
  exit 1
fi
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
SSH_PORT=$1
IMAGE_REGISTER=dela/vm_image_scripts/image_register.sh
cp dela/vm_image_scripts/image_register_template.sh ${IMAGE_REGISTER}
chmod +x ${IMAGE_REGISTER}
if [ $2 = "hopssite" ]; then
  sed -i -e "s/{REPLACE_DOMAIN}/hops.site/g" ${IMAGE_REGISTER}
  sed -i -e "s/{REPLACE_REGISTER_PORT}/443/g" ${IMAGE_REGISTER}
  sed -i -e "s/{REPLACE_DOMAIN_PREFIX}/https/g" ${IMAGE_REGISTER}
elif [ $2 = "bbc5" ]; then
  sed -i -e "s/{REPLACE_DOMAIN}/bbc5.sics.se/g" ${IMAGE_REGISTER}
  sed -i -e "s/{REPLACE_REGISTER_PORT}/8080/g" ${IMAGE_REGISTER}
  sed -i -e "s/{REPLACE_DOMAIN_PREFIX}/http/g" ${IMAGE_REGISTER}
else
  echo "wrong type hopssite/bbc5"
  exit 1
fi
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'sudo cp /home/vagrant/.ssh/authorized_keys /home/glassfish/.ssh/; sudo chown glassfish:glassfish /home/glassfish/.ssh/authorized_keys'
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/csr-ca.py glassfish@localhost:/srv/hops/domains/domain1/bin
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'sudo chown glassfish:root /srv/hops/domains/domain1/bin/csr-ca.py; sudo chmod 750 /srv/hops/domains/domain1/bin/csr-ca.py'
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'sudo rm /home/glassfish/.ssh/authorized_keys'
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'sudo mkdir -p /srv/hops/hopssite; sudo chown vagrant:vagrant /srv/hops/hopssite'
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} ${IMAGE_REGISTER} vagrant@localhost:/srv/hops/hopssite
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'chmod +x /srv/hops/hopssite/image_register.sh'
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/register_data_template.json vagrant@localhost:/srv/hops/hopssite
rm ${IMAGE_REGISTER}

#echo "setting http and https forwarded ports in variables"
PUBLIC_HTTP=$(cat Vagrantfile | grep 8080 | awk '{print($3)}' | cut -d ">" -f 2 | cut -d "}" -f 1)
PUBLIC_HTTPS=$(cat Vagrantfile | grep 8181 | awk '{print($3)}' | cut -d ">" -f 2 | cut -d "}" -f 1)

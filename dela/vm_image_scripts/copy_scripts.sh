#!/bin/bash
set -e
if [ $# -ne 1 ] ; then
  echo "first param - vm ssh forwarder port"
  exit 1
fi
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
SSH_PORT=$1
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'sudo cp /home/vagrant/.ssh/authorized_keys /home/glassfish/.ssh/; sudo chown glassfish:glassfish /home/glassfish/.ssh/authorized_keys'
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/csr-ca.py glassfish@localhost:/srv/hops/domains/domain1/bin
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'sudo rm /home/glassfish/.ssh/authorized_keys'
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'sudo mkdir -p /srv/hops/hopssite; sudo chown vagrant:vagrant /srv/hops/hopssite'
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/image_register.sh vagrant@localhost:/srv/hops/hopssite
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/register_data_template.json vagrant@localhost:/srv/hops/hopssite
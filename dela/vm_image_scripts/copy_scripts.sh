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
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/csr-ca.py vagrant@localhost:/srv/hops/domains/domain1/bin
ssh -i ~/.vagrant.d/insecure_private_key -p ${SSH_PORT} vagrant@localhost 'mkdir -p /srv/hops/hopssite'
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/image_register.sh vagrant@localhost:/srv/hops/hopssite
scp -i ~/.vagrant.d/insecure_private_key -P ${SSH_PORT} dela/vm_image_scripts/register_data_template.json vagrant@localhost:/srv/hops/hopssite
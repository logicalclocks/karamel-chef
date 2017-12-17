#!/bin/bash
set -e
ssh -i ~/.vagrant.d/insecure_private_key -p {SSH_P} vagrant@localhost 'cd /srv/hops/hopssite; sudo ./hs_install.sh'
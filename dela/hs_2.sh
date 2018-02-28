#!/bin/bash
set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
KCHEF_DIR=${PWD}
${KCHEF_DIR}/vbox.sh
${KCHEF_DIR}/run.sh hopssite 1 hopssite no-random-ports
${KCHEF_DIR}/dela/running/udp_hacky_fix.sh

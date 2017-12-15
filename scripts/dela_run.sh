#!/bin/bash
set -e
if [ ! -d "scripts" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
KCHEF_DIR=`pwd`
${KCHEF_DIR}/scripts/dela_setup.sh
${KCHEF_DIR}/run.sh dela 1 dela no-random-ports
${KCHEF_DIR}/scripts/running/udp_hacky_fix.sh

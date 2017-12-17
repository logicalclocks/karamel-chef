#!/bin/bash
set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
KCHEF_DIR=${PWD}
${KCHEF_DIR}/dela/running/register.sh
${KCHEF_DIR}/dela/running/hopssite.sh
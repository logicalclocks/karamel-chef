#!/bin/bash
set -e
if [ $# -ne 1 ] ; then
  echo "first param - dela env file"
  exit 1
fi
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
if [ ! -d "dela/running" ]; then
  mkdir dela/running
fi 
KCHEF_DIR=${PWD}
cp $1 ${KCHEF_DIR}/dela/running/dela_env.sh
chmod +x ${KCHEF_DIR}/dela/running/dela_env.sh
${KCHEF_DIR}/dela/dela_ports.sh
${KCHEF_DIR}/dela/dela_setup.sh
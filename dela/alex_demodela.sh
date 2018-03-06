#!/bin/bash
set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
./dela/alex_demodela_1.sh alex_demodela
./run.sh ubuntu 1 demodela

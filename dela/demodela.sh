#!/bin/bash
set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
if [ $# -ne 1 ] ; then
  echo "first param - demodela type"
  exit 1
fi
./dela/demodela_1.sh $1
./run.sh ubuntu 1 demodela

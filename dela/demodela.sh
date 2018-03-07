#!/bin/bash
set -e
if [ ! -d "dela" ]; then
  echo "Run the script from the karamel-chef dir"
  exit 1
fi
if [ $# -ne 1 ] ; then
  echo "first param - demodela type hopssite/bbc5"
  exit 1
fi
if [ $1 = "hopssite" ]; then
  ./dela/demodela_1.sh hopssite_demodela
elif [ $1 = "bbc5" ]; then
  ./dela/demodela_1.sh bbc5_demodela
else
  ./dela/demodela_1.sh $1
fi
./run.sh ubuntu 1 demodela

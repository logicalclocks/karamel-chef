#!/bin/bash
if [ $# -eq 1 ] ; then
  echo "$1 - running dir"
  exit 1
fi
$1/../dela_setup.sh $1
$1/../../run.sh dela 1 dela no-random-ports
$1/udp_hacky_fix.sh

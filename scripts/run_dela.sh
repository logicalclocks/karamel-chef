#!/bin/bash
./dela_setup.sh
cd ..
./run.sh dela 1 dela no-random-ports
cd scripts
./dela_udp_hacky_fix.sh

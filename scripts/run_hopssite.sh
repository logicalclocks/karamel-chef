#!/bin/bash
./hs_setup.sh hs_env.sh
cd ..
./run.sh hopssite 1 hopssite no-random-ports
cd scripts
./hs_udp_hacky_fix.sh
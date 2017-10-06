#!/bin/bash
./hs_env.sh
./run.sh hopssite 1 hopssite no-random-ports
./hs_udp_hacky_fix.sh
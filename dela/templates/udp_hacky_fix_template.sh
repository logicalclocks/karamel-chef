#!/bin/bash

echo "this is a hack fix for udp port forwarding - waiting for 1min - be patient"
sleep 1m
echo "abc" | nc -u {CLUSTER_DOMAIN} {DELA1_P}
echo "abc" | nc -u {CLUSTER_DOMAIN} {DELA2_P}
echo "abc" | nc -u {CLUSTER_DOMAIN} {DELA3_P}
echo "hack completed"
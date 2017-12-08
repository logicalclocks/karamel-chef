#!/bin/bash

echo "this is a hack fix for udp port forwarding - waiting for 1min - be patient"
sleep 1m
echo "abc" | nc -u {cluster_domain} {DELA1_P}
echo "abc" | nc -u {cluster_domain} {DELA2_P}
echo "abc" | nc -u {cluster_domain} {DELA3_P}
echo "hack completed"
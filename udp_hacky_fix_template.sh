#!/bin/bash

echo "this is a hack fix for udp port forwarding - waiting for 1min - be patient"
sleep 1m
echo "abc" | nc -u {cluster_domain} {delaport1}
echo "abc" | nc -u {cluster_domain} {delaport2}
echo "abc" | nc -u {cluster_domain} {delaport3}
echo "hack completed"
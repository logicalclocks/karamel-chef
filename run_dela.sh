#!/bin/bash
./run.sh  dela 1 dela no-random-ports

echo "this is a hack fix for udp port forwarding waiting for 1min - be patient"
sleep 1m
echo "abc" | nc -u bbc1.sics.se 42101
echo "abc" | nc -u bbc1.sics.se 43101
echo "abc" | nc -u bbc1.sics.se 44101
echo "hack completed"
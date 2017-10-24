#!/bin/bash

echo "this is a hack fix for udp port forwarding - waiting for 1min - be patient"
echo "if nc prints a warning/error - the dela service might not work on your installation"
sleep 1m
echo "abc" | nc -u localhost 42011
echo "abc" | nc -u localhost 42012
echo "abc" | nc -u localhost 42013
echo "hack completed"

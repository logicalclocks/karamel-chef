#!/bin/bash

echo "this is a hack fix for udp port forwarding - waiting for 1min - be patient"
echo "if nc prints a warning/error - the dela service might not work on your installation"
sleep 1m
echo "abc" | nc -u localhost 42001
echo "abc" | nc -u localhost 42002
echo "abc" | nc -u localhost 42003
echo "hack completed"

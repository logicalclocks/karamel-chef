#!/bin/bash

sudo sed -i \"s/-debug false/-debug true/\" /lib/systemd/system/glassfish-domain1.service
sudo systemctl daemon-reload
echo "Restarting glassfish in debug mode. This will take 5 mins...."
sudo systemctl restart glassfish-domain1


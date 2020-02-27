#!/bin/bash

script=$1
NAME=${script:0:3}


GCP_USER=$USER
PROJECT=hazel-charter-222806
ZONE=us-east1-b
REGION=us-east1

BOOT_SIZE=80GB

RAW_SSH_KEY="${USER}:$(cat /home/$USER/.ssh/id_rsa.pub)"
printf -v ESCAPED_SSH_KEY "%q\n" "$RAW_SSH_KEY"

PORTS=karamel,http-server,https-server
SUBNET=default

MACHINE_TYPE=n1-standard-8
IMAGE=centos-7-v20200205
IMAGE_PROJECT=centos-cloud

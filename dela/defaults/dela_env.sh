#!/bin/bash

#these variables are used together with 'sed' so please make sure to escape all / characters
GITHUB="hopshadoop\/hopsworks-chef"
BRANCH="master"
CLUSTER_MULTI_USER=false
CLUSTER_OS="ubuntu"

CLIENT_TYPE="FULL_CLIENT"
#CLUSTER_SUFIX will be used as the three last digits for all the vm forwarded ports.
#Make sure that different clusters working on the same machine have different suffixes
CLUSTER_SUFFIX=101
#domain of the machine where the cluster vm is being spin up
CLUSTER_DOMAIN="bbc1.sics.se"
#email used to register with hopssite
CLUSTER_EMAIL="dela1@gmail.com"
#password to register the hopsworks instance on the hopssite
CLUSTER_PASSWORD="change_me"
#source for war/ear packages
SOURCE_CODE="http:\/\/snurran.sics.se\/hops\/dela"
#Company and Unit combination has to be unique for each cluster registered with a specific hopssite instance
CLUSTER_ORG="hopsworks"
CLUSTER_UNIT="dela1"
CLUSTER_MANUAL_REGISTER="false"

#suffix and domain for your hopssite instance
HOPSSITE_SUFFIX=100
HOPSSITE_DOMAIN="bbc1.sics.se"
#!/bin/bash

#these variables are used together with 'sed' so please make sure to escape all / characters
GITHUB="AlexHopsworks\/hopsworks-chef"
BRANCH="0.4.2"
CLUSTER_MULTI_USER=false
CLUSTER_OS="ubuntu"

CLIENT_TYPE="FULL_CLIENT"
#CLUSTER_SUFIX will be used as the three last digits for all the vm forwarded ports.
#Make sure that different clusters working on the same machine have different suffixes
CLUSTER_SUFFIX=200
#domain of the machine where the cluster vm is being spin up
CLUSTER_DOMAIN="bbc5.sics.se"
#email used to register with hopssite
CLUSTER_EMAIL="delahs@gmail.com"
#password to register the hopsworks instance on the hopssite
CLUSTER_PASSWORD="Abcd1234"
#source for war/ear packages
SOURCE_CODE="http:\/\/snurran.sics.se\/hops\/alex"
#Company and Unit combination has to be unique for each cluster registered with a specific hopssite instance
CLUSTER_ORG="hopsworks"
CLUSTER_UNIT="hs"

DELA_VERSION="0.1.0"
HS_VERSION="0.4.2"
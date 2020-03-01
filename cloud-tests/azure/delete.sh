#!/bin/bash

. config.sh

az group delete --name $RESOURCE_GROUP

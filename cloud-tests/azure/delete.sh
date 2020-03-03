#!/bin/bash

. config.sh $1

az vm delete --name $NAME

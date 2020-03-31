#!/bin/bash

if [ $# -ne 1 ] ; then
    echo "Usage: $0 [cpu|gpu|cluster|benchmark]"
    echo "Delete an instance on Azure"
    exit 1
fi    

rm_instance()
{
    az vm delete -g $RESOURCE_GROUP --name $NAME --yes --no-wait    
}

. config.sh

if [ "$1" = "cpu" ] ; then
    . config.sh cpu
    rm_instance
elif [ "$1" = "gpu" ] ; then
    . config.sh gpu
    rm_instance    
elif [ "$1" = "cluster" ] ; then
    . config.sh cpu
    rm_instance
    . config.sh gpu
    rm_instance    
    . config.sh cluster
    rm_instance
elif [ "$1" = "benchmark" ] ; then
    NAME="ben"
    rm_instance

    CPUS=$(cat .cpus)
    GPUS=$(cat .gpus)
    for i in $(seq 1 ${CPUS}) ;
    do
        NAME="cp${i}"
        rm_instance
    done
    
    for i in $(seq 1 ${GPUS}) ;
    do
        NAME="gp${i}"
        rm_instance
    done
else
    echo "Invalid argument."
    exit 1
fi

echo ""
echo "Deleting instance $NAME in the background (it will take a few mins)."
echo "Run './list.sh' to check when it is finshed"
echo ""

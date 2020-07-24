#!/bin/bash


help()
{
    echo "Usage: $0 [vm_name_prefix]"
    echo "Delete a Hopsworks cluster on GCP. "
    exit 1
}

if [ "$1" == "-h" ] ; then
   help
fi

if [ $# -lt 1 ] ; then
   help
fi    

rm_instance()
{
    echo "Deleting $NAME"
    nohup gcloud compute instances delete -q $NAME > gcp-installer.log 2>&1 </dev/null &
}

prefix=$USER

if [ $# -gt 0 ] ; then
    prefix=$1
fi    


#reg=${REGION/-/}
#NAME="ben${reg}"
. config.sh $prefix "head"
rm_instance

CPUS=$(cat .cpus)
GPUS=$(cat .gpus)
for i in $(seq 1 ${CPUS}) ;
do
#    NAME="${prefix}cp${i}${reg}"
    NAME="${prefix}cp${i}"    
    rm_instance
done

for i in $(seq 1 ${GPUS}) ;
do
    NAME="${prefix}gp${i}"        
    rm_instance
done

echo ""
echo "Deleting cluster with prefix:  $prefix."
echo "Check log file for progress: "
echo "tail -f gcp-installer.log"
echo ""

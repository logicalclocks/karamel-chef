#!/bin/bash

help()
{
    echo ""
    echo "Usage: $0 cpu|gpu|cluster [skip-create] [community]"
    echo "Create a VM or a cluster and install Hopsworks on it."
    echo ""    
    exit 1
}

if [ $# -lt 1 ] ; then
    help
fi

error_download_url()
{
    echo ""
    echo "Error. You need to export the following environment variable to run this script:"
    echo "export DOWNLOAD_URL=https://path/to/hopsworks/enterprise/binaries"
    echo ""    
    exit
}

get_ips()
{
    IP=$(./_list_public.sh cluster)
    PRIVATE_IP=$(./_list_private.sh cluster)    
    echo -e "Head node.\t Public IP: $IP \t Private IP: $PRIVATE_IP"

    CPU=$(./_list_public.sh cpu)
    PRIVATE_CPU=$(./_list_private.sh cpu)
    echo -e "Cpu node.\t Public IP: $CPU \t Private IP: $PRIVATE_CPU"


    GPU=$(./_list_public.sh gpu)
    PRIVATE_GPU=$(./_list_private.sh gpu)
    echo -e "Gpu node.\t Public IP: $GPU \t Private IP: $PRIVATE_GPU"
}    

clear_known_hosts()
{
   echo "   ssh-keygen -R $host_ip -f /home/$USER/.ssh/known_host"
   ssh-keygen -R $host_ip -f /home/$USER/.ssh/known_hosts 
}    

###################################################################
#   MAIN                                                          #
###################################################################

if [ "$1" != "cpu" ] && [ "$1" != "gpu" ] && [ "$1" != "cluster" ] ; then
    help
    exit 3
fi

host_ip=
. config.sh $1

get_ips

if [ "$2" == "community" ] || [ "$3" == "community" ] ; then
    HOPSWORKS_VERSION=cluster
else
    HOPSWORKS_VERSION=enterprise    
fi

if [ ! "$2" == "skip-create" ] ; then
    IP=$(./_list_public.sh $1)    
    if [ "$IP" != "" ] ; then
	echo "VM already created and running at: $IP"
	echo "Exiting..."
	exit 3
    fi
    echo ""
    echo "Creating VM(s) ...."
    echo ""    
    ./_create.sh $1
else
    echo "Skipping VM creation...."
fi	

get_ips

IP=$(./_list_public.sh $1)
echo "IP: $IP for $NAME"

host_ip=$IP
clear_known_hosts

if [[ "$IMAGE" == *"centos"* ]]; then
    echo "ssh -t -o StrictHostKeyChecking=no $IP \"sudo yum install wget -y > /dev/null\""
    ssh -t -o StrictHostKeyChecking=no $IP "sudo yum install wget -y > /dev/null"
fi    


echo "Installing installer on $IP"
ssh -t -o StrictHostKeyChecking=no $IP "wget -nc ${CLUSTER_DEFINITION_BRANCH}/hopsworks-installer.sh && chmod +x hopsworks-installer.sh"

if [ $? -ne 0 ] ; then
    echo "Problem installing installer. Exiting..."
    exit 1
fi    


if [ "$1" = "cluster" ] ; then
    ssh -t -o StrictHostKeyChecking=no $IP "if [ ! -e ~/.ssh/id_rsa.pub ] ; then cat /dev/zero | ssh-keygen -q -N \"\" ; fi"
    pubkey=$(ssh -t -o StrictHostKeyChecking=no $IP "cat ~/.ssh/id_rsa.pub")

    keyfile=".pubkey.pub"
    echo "$pubkey" > $keyfile
    echo ""
    echo "Public key for head node is:"
    echo "$pubkey"
    echo ""

    host_ip=$CPU
    clear_known_hosts
    host_ip=$GPU
    clear_known_hosts
    
    WORKERS="-w ${PRIVATE_CPU},${PRIVATE_GPU}"

    ssh-copy-id -o StrictHostKeyChecking=no -f -i $keyfile $CPU
    ssh -t -o StrictHostKeyChecking=no $IP "ssh -t -o StrictHostKeyChecking=no $PRIVATE_CPU \"pwd\""
    if [ $? -ne 0 ] ; then
	echo ""
	echo "Error. Public key SSH from $IP to $PRIVATE_CPU not working."
	echo "Exiting..."
	echo ""
	exit 9
    else
	echo "Success: SSH from $IP to $CPU_PRIVATE"
    fi

    ssh-copy-id -o StrictHostKeyChecking=no -f -i $keyfile $GPU
    ssh -t -o StrictHostKeyChecking=no $IP "ssh -t -o StrictHostKeyChecking=no $PRIVATE_GPU \"pwd\""
    if [ $? -ne 0 ] ; then
	echo ""
	echo "Error. Public key SSH from $IP to $PRIVATE_GPU not working."
	echo "Exiting..."
	echo ""
	exit 10
    else
	echo "Success: SSH from $IP to $GPU_PRIVATE"
    fi

else
    WORKERS="-w none"
fi    

DOWNLOAD=""
if [ "$DOWNLOAD_URL" != "" ] ; then
  DOWNLOAD="-d $DOWNLOAD_URL"
fi
echo
echo "ssh -t -o StrictHostKeyChecking=no $IP "/home/$USER/hopsworks-installer.sh -i $HOPSWORKS_VERSION -ni -c gcp $DOWNLOAD $WORKERS && sleep 5""
ssh -t -o StrictHostKeyChecking=no $IP "/home/$USER/hopsworks-installer.sh -i $HOPSWORKS_VERSION -ni -c gcp $DOWNLOAD $WORKERS && sleep 5"

if [ $? -ne 0 ] ; then
    echo "Problem running installer. Exiting..."
    exit 2
fi

echo ""
echo "****************************************"
echo "*                                      *"
echo "* Public IP access to Hopsworks at:    *"
echo "*   https://${IP}/hopsworks    *"
echo "*                                      *"
echo "* View nstallation progress:           *"
echo "*   ssh ${IP}                  *"
echo "*   tail -f installation.log           *"
echo "****************************************"

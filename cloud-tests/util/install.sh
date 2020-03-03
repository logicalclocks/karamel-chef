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
    IP=$(./_list_public.sh clu)
    PRIVATE_IP=$(./_list_private.sh clu)    
    # IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')
    # PRIVATE_IP=$(gcloud compute instances list | grep $NAME | awk '{ print $4 }')
    echo -e "Head node.\t Public IP: $IP \t Private IP: $PRIVATE_IP"

    CPU=$(./_list_public.sh cpu)
    PRIVATE_CPU=$(./_list_private.sh cpu)
#    CPU=$(gcloud compute instances list | grep "cpu" | awk '{ print $5 }')
#    PRIVATE_CPU=$(gcloud compute instances list | grep "cpu" | awk '{ print $4 }')
    echo -e "Cpu node.\t Public IP: $CPU \t Private IP: $PRIVATE_CPU"


    GPU=$(./_list_public.sh gpu)
    PRIVATE_GPU=$(./_list_private.sh gpu)
#    GPU=$(gcloud compute instances list | grep "gpu" | awk '{ print $5 }')
#    PRIVATE_GPU=$(gcloud compute instances list | grep "gpu" | awk '{ print $4 }')
    echo -e "Gpu node.\t Public IP: $GPU \t Private IP: $PRIVATE_GPU"
}    

host_ip=
clear_known_hosts()
{
   ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $host_ip    
}    

get_ips

exit

if [ "$DOWNLOAD_URL" == "" ] ; then
    if [ -e env.sh ] ; then
	. env.sh
        if [ "$DOWNLOAD_URL" == "" ] ; then
	    error_download_url
	fi
    else
	error_download_url
    fi
fi    


if [ "$1" = "cpu" ] ; then
    job="cpu"
elif [ "$1" = "gpu" ] ; then
    job="gpu"
elif [ "$1" = "cluster" ] ; then
    job="cluster"
else
    help
fi

. config.sh $job

IP=$(./_list_public.sh $NAME)
#IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')

if [ "$2" == "community" ] || [ "$3" == "community" ] ; then
    HOPSWORKS_VERSION=cluster
else
    HOPSWORKS_VERSION=enterprise    
fi

if [ ! "$2" == "skip-create" ] ; then
    if [ "$IP" != "" ] ; then
	echo "VM already created and running at: $IP"
	echo "Exiting..."
	exit 3
    fi
    echo ""
    echo "Creating VM(s) ...."
    echo ""    
    ./_create.sh $job
else
    echo "Skipping VM creation...."
fi	


echo ""
echo "gcloud compute instances list ...."
echo ""


if [ "$job" == "cluster" ] ; then # wait for all VMs to have started

    while [[ "$IP" == "" ]] || [[ "$CPU" == "" ]] || [[ "$GPU" == "" ]] ; do
	get_ips
    done
else
    get_ips
fi    


host_ip=$IP
clear_known_hosts

if [[ "$IMAGE" == *"centos"* ]]; then
    echo "ssh -t -o StrictHostKeyChecking=no $IP \"sudo yum install wget -y > /dev/null\""
    ssh -t -o StrictHostKeyChecking=no $IP "sudo yum install wget -y > /dev/null"
fi    


echo "Installing installer on $IP"
ssh -t -o StrictHostKeyChecking=no $IP "wget -nc ${BRANCH}/hopsworks-installer.sh && chmod +x hopsworks-installer.sh"

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
echo ""
echo "ssh -t -o StrictHostKeyChecking=no $IP \"/home/$USER/hopsworks-installer.sh -i $HOPSWORKS_VERSION -ni -c gcp -d $DOWNLOAD_URL $WORKERS\""
ssh -t -o StrictHostKeyChecking=no $IP "/home/$USER/hopsworks-installer.sh -i $HOPSWORKS_VERSION -ni -c gcp -d $DOWNLOAD_URL $WORKERS"

if [ $? -ne 0 ] ; then
    echo "Problem running installer. Exiting..."
    exit 2
fi

ssh -t -o StrictHostKeyChecking=no $IP "cd karamel-0.6 && setsid ./bin/karamel -headless -launch ../cluster-defns/hopsworks-installer-active.yml  > ../installation.log 2>&1 &"

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

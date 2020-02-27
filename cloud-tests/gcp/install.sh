#!/bin/bash

if [ $# -lt 1 ] ; then
    echo ""
    echo "Usage: $0 cpu|gpu|cluster [skip-create]"
    echo "Create a VM or a cluster and install Hopsworks on it."
    echo ""    
    exit 1
fi

error_download_url()
{
    echo ""
    echo "Error. You need to export the following environment variable to run this script:"
    echo "export DOWNLOAD_URL=https://path/to/hopsworks/enterprise/binaries"
    echo ""    
    exit
}

host_ip=
test_ssh()
{
    ssh -t -o StrictHostKeyChecking=no $host_ip "pwd"
    if [ $? -ne 0 ] ; then
	echo "	ssh-keygen -f \"/home/$USER/.ssh/known_hosts\" -R $host_ip"
	ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $host_ip
    fi    
}    

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
    echo "Invalid argument: $1"
    echo "Usage: $0 cpu|gpu|cluster [skip-create]"
    exit 1
fi

. config.sh $job

IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')

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


IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')
PRIVATE_IP=$(gcloud compute instances list | grep $NAME | awk '{ print $4 }')
echo -e "Head node.\t Public IP: $IP \t Private IP: $PRIVATE_IP"

CPU=$(gcloud compute instances list | grep "cpu" | awk '{ print $5 }')
PRIVATE_CPU=$(gcloud compute instances list | grep "cpu" | awk '{ print $4 }')
echo -e "Cpu node.\t Public IP: $CPU \t Private IP: $PRIVATE_CPU"


GPU=$(gcloud compute instances list | grep "gpu" | awk '{ print $5 }')
PRIVATE_GPU=$(gcloud compute instances list | grep "gpu" | awk '{ print $4 }')
echo -e "Gpu node.\t Public IP: $GPU \t Private IP: $PRIVATE_GPU"
    

host_ip=$IP
test_ssh

if [[ "$IMAGE" == *"centos"* ]]; then
    ssh -t -o StrictHostKeyChecking=no $IP "sudo yum install wget -y > /dev/null"
fi    


echo "Installing installer on $IP"
ssh -t -o StrictHostKeyChecking=no $IP "wget -nc https://raw.githubusercontent.com/logicalclocks/karamel-chef/installer_improvements/hopsworks-installer.sh && chmod +x hopsworks-installer.sh"

if [ $? -ne 0 ] ; then
    echo "Problem installing installer. Exiting..."
    exit 1
fi    

if [ "$1" = "cluster" ] ; then
    ssh -t -o StrictHostKeyChecking=no $IP "if [ ! -e ~/.ssh/id_rsa.pub ] ; then cat /dev/zero | ssh-keygen -q -N \"\" ; fi"
    pubkey=$(ssh -t -o StrictHostKeyChecking=no $IP "cat ~/.ssh/id_rsa.pub")

    echo "$pubkey" > .pubkey.pub
    echo ""
    echo "Public key for head node is:"
    echo "$pubkey"
    echo ""

    host_ip=$CPU
    test_ssh
    target=$CPU
    host_ip=$GPU
    test_ssh
    
    WORKERS="-w ${PRIVATE_CPU},${PRIVATE_GPU}"

    ssh-copy-id -o StrictHostKeyChecking=no -i .pubkey.pub $CPU > /dev/null
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

    ssh-copy-id -o StrictHostKeyChecking=no -i .pubkey.pub $GPU > /dev/null
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
echo "Running installer on $IP :"
echo "./hopsworks-installer.sh -i enterprise -ni -c gcp -d $DOWNLOAD_URL $WORKERS"
echo ""
ssh -t -o StrictHostKeyChecking=no $IP "./hopsworks-installer.sh -i enterprise -ni -c gcp -d $DOWNLOAD_URL $WORKERS"

if [ $? -ne 0 ] ; then
    echo "Problem running installer. Exiting..."
    exit 2
fi    

echo ""
echo "Installation finished. Hopsworks will start running at:"
echo "https://${IP}/hopsworks"
echo ""

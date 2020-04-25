#!/bin/bash


declare -a CPU
declare -a GPU

declare -a PRIVATE_CPU
declare -a PRIVATE_GPU
HOPSWORKS_VERSION=enterprise
DOWNLOAD_URL=

help()
{
    echo ""
    echo "Usage: $0 num_cpus num_gpus [skip-create] [community]"
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
    IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')
    PRIVATE_IP=$(gcloud compute instances list | grep $NAME | awk '{ print $4 }')
    echo -e "Head node.\t Public IP: $IP \t Private IP: $PRIVATE_IP"


    CPUS=$(cat .cpus)
    GPUS=$(cat .gpus)

    for i in $(seq 1 ${CPUS}) ;
    do
        cpuid="cp${i}${REGION/-/}"
	CPU[$i]=$(gcloud compute instances list | grep "$cpuid" | awk '{ print $5 }')
	PRIVATE_CPU[$i]=$(gcloud compute instances list | grep "$cpuid" | awk '{ print $4 }')
#        echo -e "Cp${i} node.\t Public IP: ${CPU[${i}]} \t Private IP: ${PRIVATE_CPU[${i}]}"
    done
    
    for j in $(seq 1 ${GPUS}) ;
    do
        gpuid="cp${j}${REGION/-/}"	
	GPU[$j]=$(gcloud compute instances list | grep "$gpuid" | awk '{ print $5 }')
	PRIVATE_GPU[$j]=$(gcloud compute instances list | grep "$gpuid" | awk '{ print $4 }')
#        echo -e "GPU${j} node.\t Public IP: ${GPU[${j}]} \t Private IP: ${PRIVATE_GPU[${i}]}"
    done
}    


host_ip=
clear_known_hosts()
{
   echo "   ssh-keygen -R $host_ip -f /home/$USER/.ssh/known_host"
   ssh-keygen -R $host_ip -f "/home/$USER/.ssh/known_hosts" 
}    


if [ $# -lt 2 ] ; then
    help
fi
CPUS=$1
GPUS=$2

. config.sh "benchmmark"

IP=$(gcloud compute instances list | grep $NAME | awk '{ print $5 }')

if [ "$3" == "community" ] || [ "$4" == "community" ] ; then
    HOPSWORKS_VERSION=cluster
else
    if [ "$ENTERPRISE_DOWNLOAD_URL" == "" ] ; then
	if [ -e env.sh ] ; then
	    . env.sh
	    DOWNLOAD_URL="-d $ENTERPRISE_DOWNLOAD_URL"
            if [ "$ENTERPRISE_DOWNLOAD_URL" == "" ] ; then
		error_download_url
	    fi
	else
	    error_download_url
	fi
    else
        DOWNLOAD_URL="-d $ENTERPRISE_DOWNLOAD_URL"	
    fi    
fi

echo "Installing version: $HOPSWORKS_VERSION"

if [ ! "$3" == "skip-create" ] ; then
    if [ "$IP" != "" ] ; then
	echo "VM already created and running at: $IP"
	echo "Exiting..."
	exit 3
    fi
    echo ""
    echo "Creating VM(s) ...."
    echo ""    
    ./_create.sh "benchmark" $CPUS $GPUS
else
    echo "Skipping VM creation...."
fi	


get_ips

echo ""
echo "gcloud compute instances list ...."
echo ""


host_ip=$IP
clear_known_hosts


if [[ "$IMAGE" == *"centos"* ]]; then
    ssh -t -o StrictHostKeyChecking=no $IP "sudo yum install wget -y > /dev/null"
fi    


echo "Installing installer on $IP"
scp -o StrictHostKeyChecking=no ../../hopsworks-installer.sh ${IP}:
ssh -t -o StrictHostKeyChecking=no $IP "chmod +x hopsworks-installer.sh; mkdir -p cluster-defns"
scp -o StrictHostKeyChecking=no ../../cluster-defns/hopsworks-installer.yml ${IP}:~/cluster-defns/
scp -o StrictHostKeyChecking=no ../../cluster-defns/hopsworks-worker.yml ${IP}:~/cluster-defns/
scp -o StrictHostKeyChecking=no ../../cluster-defns/hopsworks-worker-gpu.yml ${IP}:~/cluster-defns/

if [ $? -ne 0 ] ; then
    echo "Problem installing installer. Exiting..."
    exit 1
fi    

ssh -t -o StrictHostKeyChecking=no $IP "if [ ! -e ~/.ssh/id_rsa.pub ] ; then cat /dev/zero | ssh-keygen -q -N \"\" ; fi"
pubkey=$(ssh -t -o StrictHostKeyChecking=no $IP "cat ~/.ssh/id_rsa.pub")

keyfile=".pubkey.pub"
echo "$pubkey" > $keyfile
echo ""
echo "Public key for head node is:"
echo "$pubkey"
echo ""


WORKERS="-w "
for i in $(seq 1 ${CPUS}) ;
do
    host_ip=${CPU[${i}]}
    echo "I think host_ip is ${CPU[$i]}"
    echo "I think host_ip is ${CPU[${i}]}"
    echo "All  hosts ${CPU[*]}"    
    clear_known_hosts

    ssh-copy-id -o StrictHostKeyChecking=no -f -i $keyfile ${CPU[${i}]}
    ssh -t -o StrictHostKeyChecking=no $IP "ssh -t -o StrictHostKeyChecking=no ${PRIVATE_CPU[${i}]} \"pwd\""
    if [ $? -ne 0 ] ; then
	echo ""
	echo "Error. Public key SSH from $IP to ${PRIVATE_CPU[${i}]} not working."
	echo "Exiting..."
	echo ""
	exit 9
    else
	echo "Success: SSH from $IP to ${PRIVATE_CPU[${i}]}"
    fi

    WORKERS="${WORKERS}${PRIVATE_CPU[${i}]},"
done

WORKERS=${WORKERS::-1}
for i in $(seq 1 ${GPUS}) ;
do
    host_ip=$GPU[${i}]}
    echo "I think host_ip is ${GPU[$i]}"
    echo "I think host_ip is ${GPU[${i}]}"
    echo "All  hosts ${GPU[*]}"    
    clear_known_hosts
    ssh-copy-id -o StrictHostKeyChecking=no -f -i $keyfile ${GPU[${i}]}
    ssh -t -o StrictHostKeyChecking=no $IP "ssh -t -o StrictHostKeyChecking=no ${PRIVATE_GPU[${i}]} \"pwd\""
    if [ $? -ne 0 ] ; then
	echo ""
	echo "Error. Public key SSH from $IP to ${PRIVATE_GPU[${i}]} not working."
	echo "Exiting..."
	echo ""
	exit 9
    else
	echo "Success: SSH from $IP to ${PRIVATE_GPU[${i}]}"
    fi

    WORKERS="${WORKERS},${PRIVATE_GPU[${i}]}"
done

echo ""
echo "Running installer on $IP :"
echo ""
echo "ssh -t -o StrictHostKeyChecking=no $IP \"/home/$USER/hopsworks-installer.sh -i $HOPSWORKS_VERSION -ni -c $CLOUD $DOWNLOAD_URL $WORKERS\""
ssh -t -o StrictHostKeyChecking=no $IP "/home/$USER/hopsworks-installer.sh -i $HOPSWORKS_VERSION -ni -c $CLOUD $DOWNLOAD_URL $WORKERS && sleep 5"

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
echo "* View installation progress:           *"
echo " ssh ${IP} \"tail -f installation.log\"   "
echo "****************************************"

#!/bin/bash
cd ..
printf "Enter the Enterprise username: "
read  USERNAME
printf "Enter the Enterprise password: "
read -s PASSWORD
echo ""
export ENTERPRISE_USERNAME=$USERNAME

printf "Enter a name (prefix) for the VM: "
read name

echo "The cluster name prefix is: $name"

echo "Number of CPUs for your instance (8, 16, 32. Default: 8):"
read cpus

if [ "$cpus" == "" ] ; then
  cpus=8
  echo "Using 8 cpus"
fi

echo "Number of NVMe disks for this instance (2, 4, 6, 8): (default: 4)"
read nvmes

if [ "$nvmes" == "" ] ; then
    nvmes=4
fi
echo "Using $nvmes nvme disks"

nvme_str=""
if [ $nvmes -gt 0 ] ; then
  start=1
  for (( i=1; i<=$nvmes; i++ ))
  do
   nvme_str="$nvme_str /dev/nvme0n$i"
  done
fi

ENTERPRISE_PASSWORD=$PASSWORD ./hopsworks-cloud-installer.sh -n $name -i enterprise -ni -c gcp -de https://nexus.hops.works/repository -ht n1-standard-${cpus} -nvme $nvmes -drc

echo ""
echo "https://www.digitalocean.com/community/tutorials/how-to-create-raid-arrays-with-mdadm-on-ubuntu-22-04"
echo "ssh ...."
echo "Then run:"
echo ""
echo "sudo su"
nvme_strs = $( for 
echo "sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=4 /dev/nvme0n1 /dev/nvme0n2 /dev/nvme0n3 /dev/nvme0n4 "
echo "sudo mkfs.ext4 -F /dev/md0"
echo "sudo mkdir -p /mnt/md0"
echo "sudo mount /dev/md0 /mnt/md0"
echo "sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf"
echo "sudo update-initramfs -u"
echo "echo '/dev/md0 /mnt/md0 ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab"
echo ""
echo "Then edit: ~/cluster-definitions/hopsworks-installation.yml"
echo "Change disk dir to: /mnt/md0"
echo "mkdir -p /mnt/md0/hops"
echo "mkdir /mnt/md0/hopsworks-data"
echo "cd /srv"
echo "ln -s /mnt/md0/hops ."
echo "ln -s /mnt/md0/hopsworks-data ."
echo ""
echo "Change rondb diskdata to /srv/hops/ndb-diskdata. That directory will be created for you in ndb::ndbd"


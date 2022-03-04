#!/bin/bash

export USER=__USER__
export VERSION="2.6.0-SNAPSHOT"
export SERVER="dev4.hops.works"
export HOPSWORKS_DIR="/home/$USER/Projects/hopsworks-ee"
export WAR=$1 # set to 'war' to also deploy the war file

cd /tmp

rm -f hopsworks-*
scp -i ~/.ssh/id_rsa_dev ${USER}@${SERVER}:${HOPSWORKS_DIR}/hopsworks-ear/target/*.ear .

if [ "$WAR" == "war" ] ; then 
  rm -f hopsworks*.war
  scp -i ~/.ssh/id_rsa_dev ${USER}@${SERVER}:${HOPSWORKS_DIR}/hopsworks-web/target/*.war .
fi

sudo su glassfish <<EOF


/srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false undeploy --target server hopsworks-ear:$VERSION

echo "Installing new hopsworks-ear.ear"
/srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false --echo=true --terse=false deploy --name hopsworks-ear:$VERSION --force=true --precompilejsp=true --verify=false --enabled=true --generatermistubs=false --availabilityenabled=false --asyncreplication=false --target server --keepreposdir=false --keepfailedstubs=false --isredeploy=false --logreportederrors=true --keepstate=false --lbenabled true --_classicstyle=false --upload=true hopsworks-ear.ear


if [ "$WAR" == "war" ] ; then 

  /srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false undeploy --target server hopsworks-web:$VERSION

  /srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false --echo=true --terse=false deploy --name hopsworks-web:$VERSION --force=true --precompilejsp=true --verify=false --enabled=true --generatermistubs=false --availabilityenabled=false --asyncreplication=false --target server --keepreposdir=false --keepfailedstubs=false --isredeploy=false --logreportederrors=true --keepstate=false --lbenabled true --_classicstyle=false --upload=true hopsworks-web.war

fi

EOF


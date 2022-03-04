#!/bin/bash

USER=jdowling
VERSION="2.6.0-SNAPSHOT"

cd /tmp

rm -f hopsworks-*
scp -i ~/.ssh/id_rsa_dev ${USER}@dev4.hops.works:~/Projects/hopsworks-ee/hopsworks-ear/target/*.ear .

if [ "$1" == "war" ] ; then 
  rm -f hopsworks*.war
  scp -i ~/.ssh/id_rsa_dev ${USER}@dev4.hops.works:~/Projects/hopsworks-ee/hopsworks-web/target/*.war .
fi

sudo su glassfish <<EOF

#/srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false create-protocol --securityenabled=true http-1


#/srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false 

/srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false undeploy --target server hopsworks-ear:$VERSION

echo "Installing new hopsworks-ear.ear"
/srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false --echo=true --terse=false deploy --name hopsworks-ear:$VERSION --force=true --precompilejsp=true --verify=false --enabled=true --generatermistubs=false --availabilityenabled=false --asyncreplication=false --target server --keepreposdir=false --keepfailedstubs=false --isredeploy=false --logreportederrors=true --keepstate=false --lbenabled true --_classicstyle=false --upload=true hopsworks-ear.ear


if [ "$1" == "war" ] ; then 

  /srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false undeploy --target server hopsworks-web:$VERSION

  /srv/hops/glassfish/versions/current/bin/asadmin --host localhost --port 4848 --user adminuser --passwordfile /srv/hops/domains/domain1_admin_passwd --interactive=false --echo=true --terse=false deploy --name hopsworks-web:$VERSION --force=true --precompilejsp=true --verify=false --enabled=true --generatermistubs=false --availabilityenabled=false --asyncreplication=false --target server --keepreposdir=false --keepfailedstubs=false --isredeploy=false --logreportederrors=true --keepstate=false --lbenabled true --_classicstyle=false --upload=true hopsworks-web.war

fi

EOF


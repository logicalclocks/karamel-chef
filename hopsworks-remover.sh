#!/bin/bash

#set -e

sudo /srv/hops/kagent/bin/shutdown-all-local-services.sh -f

sudo rm -rf $USER/.karamel

# Don't remove /tmp/chef-solo unless there is unversioned software there
# sudo rm -rf /tmp/chef-solo/*

pushd .
cd /lib/systemd/system
sudo rm -f ndb_mgmd.service ndbmtd.service mysqld.service glassfish-domain1.service kagent.service namenode.service zookeeper.service telegraf.service elasticsearch.service datanode.service kafka.service epipe.service historyserver.service resourcemanager.service logstash.service kibana.service sparkhistoryserver.service livy.service nodemanager.service influxdb.service grafana.service hivemetastore.service hivecleaner.service

popd

sudo rm -rf /srv/hops

sudo systemctl daemon-reload
sudo systemctl reset-failed

#!/bin/bash

set -e
set -x

# Monit
yum install monit
wget -O /etc/monitrc https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/monit/monitrc
wget -O /etc/monit.d/server https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/monit/monit.d/server
service monit restart

# ActiveMQ:
cd /usr/local/src
wget https://dlcdn.apache.org//activemq/5.18.4/apache-activemq-5.18.4-bin.tar.gz
tar -xf apache-activemq-5.18.4-bin.tar.gz
mv apache-activemq-5.18.4 ../
rm apache-activemq-5.18.4-bin.tar.gz
cd ../
useradd activemq
chown -R activemq:activemq ./apache-activemq-5.18.4
# Edit jetty-realm.properties manually

# Services:
wget -O /etc/systemd/system/labkey_server.service https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/labkey_server.service
wget -O /etc/systemd/system/activemq.service https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/activemq.service


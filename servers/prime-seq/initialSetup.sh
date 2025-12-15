#!/bin/bash

set -e
set -x

# Yum:
yum install -y monit fontconfig gcc gcc-c++ ncurses-devel zlib-devel xz-devel net-tools wget python-pip skopeo graphviz
pip install Stomp

# Monit
yum install monit
wget -O /etc/monitrc https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/monit/monitrc
wget -O /etc/monit.d/server https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/monit/monit.d/server
service monit restart

# Java:
cd /usr/local/src
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz
tar -xf OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz
mv jdk-17.0.11+9 ../
rm -Rf OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz
cd ../
ln -s jdk-17.0.11+9 java

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
# Edit log4j properties to change log file location
mkdir /var/log/activemq
chown -R activemq:activemq /var/log/activemq

# Services:
wget -O /etc/systemd/system/labkey_server.service https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/labkey_server.service
wget -O /etc/systemd/system/activemq.service https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/activemq.service
systemctl daemon-reload

if [ ! -e /usr/local/tools/ ]; then
	mkdir /usr/local/tools
fi

wget -O /usr/local/tools/labkey-error-email.sh https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/labkey-error-email.sh
chmod +x /usr/local/tools/labkey-error-email.sh

wget -O /usr/local/tools/filterLogMessages.py https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/filterLogMessages.py
chmod +x /usr/local/tools/filterLogMessages.py

wget -O /usr/local/tools/activeMQ-monit.py https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/activeMQ-monit.py
chmod +x /usr/local/tools/activeMQ-monit.py

# NOTE: you must also create the file: /usr/local/etc/labkey/.dockerRegistry. This can be created using: 
# skopeo login --compat-auth-file=/usr/local/etc/labkey/.dockerRegistry
wget -O /usr/local/tools/syncDockerRegistries.sh https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/syncDockerRegistries.sh
chmod +x /usr/local/tools/syncDockerRegistries.sh
echo "*/5 * * * * labkey_submit /usr/local/tools/syncDockerRegistries.sh > /var/log/dockerSync.log 2>&1" >> /etc/cron.d/syncDockerRegistries
touch /var/log/dockerSync.log
chmod o+w /var/log/dockerSync.log
chmod 0644 /etc/cron.d/syncDockerRegistries

# LabKey
cd /usr/local/src
wget https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/prime-seq/installLabkey.sh
chmod +x installLabkey.sh
./installLabkey.sh
mkdir /usr/local/labkey/labkey-tmp
chown -R labkey:labkey /usr/local/labkey

mkdir -p /usr/local/labkey/tools
yum install libnsl
cd /usr/local/src
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.31/ncbi-blast-2.2.31+-x64-linux.tar.gz
gunzip ncbi-blast-2.2.31+-x64-linux.tar.gz
tar -xf ncbi-blast-2.2.31+-x64-linux.tar
rm ncbi-blast-2.2.31+-x64-linux.tar
mv ncbi-blast-2.2.31+ /usr/local/labkey/tools/
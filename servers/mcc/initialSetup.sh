#!/bin/bash

set -e
set -x

yum install monit fontconfig

# Monit
wget -O /etc/monitrc https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/mcc/monit/monitrc
wget -O /etc/monit.d/server https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/mcc/monit/monit.d/server
service monit restart

# Java:
cd /usr/local/src
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz
tar -xf OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz
mv jdk-17.0.11+9 ../
rm -Rf OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz
cd ../
ln -s jdk-17.0.11+9 java

# Services:
wget -O /etc/systemd/system/labkey_server.service https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/mcc/labkey_server.service
systemctl daemon-reload

if [ ! -e /usr/local/tools/ ]; then
	mkdir /usr/local/tools
fi

wget -O /usr/local/tools/labkey-error-email.sh https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/labkey-error-email.sh
chmod +x /usr/local/tools/labkey-error-email.sh

wget -O /usr/local/tools/filterLogMessages.py https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/filterLogMessages.py
chmod +x /usr/local/tools/filterLogMessages.py

# LabKey
cd /usr/local/src
mkdir -p /usr/local/labkey/labkey-tmp
chown -R mcclabkey:mcclabkey /usr/local/labkey

# Note: edit /etc/hosts to include SNPRC server
wget -O installLabKey.sh https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/servers/mcc/installLabKey.sh
chmod +x installLabKey.sh
./installLabKey.sh

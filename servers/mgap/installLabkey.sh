#!/bin/bash

#mGAP:

set -x
set -e

SETTINGS=mgapSettings.sh
if [ -e $SETTINGS ];then
	rm $SETTINGS
fi

wget -O $SETTINGS https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/${SETTINGS}

set -o allexport
source $SETTINGS
set +o allexport

if [ ! -e $LABKEY_HOME/labkey-tmp ];then
	mkdir -p $LABKEY_HOME/labkey-tmp
	chown -R $LABKEY_USER:$LABKEY_USER $LABKEY_HOME/labkey-tmp
fi

CONFIGURATION_DIR=${LABKEY_HOME}/configuration
if [ ! -e $CONFIGURATION_DIR ];then
	mkdir -p $CONFIGURATION_DIR

	wget -O ${CONFIGURATION_DIR}/application.properties https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/config/application.properties

	# Append private values:
	cat $CONFIGURATION_DIR/mgap.application.properties >> ${CONFIGURATION_DIR}/application.properties
	
	wget -O $CONFIGURATION_DIR/labkey_server.env https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/config/labkey_server.env
	wget -O $CONFIGURATION_DIR/startup.sh https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/config/startup.sh
	chmod +x $CONFIGURATION_DIR/startup.sh
fi

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

rm $INSTALL
rm $SETTINGS
#!/bin/bash

#MCC:

set -x
set -e

SETTINGS=mccSettings.sh
if [ -e $SETTINGS ];then
	rm $SETTINGS
fi

wget -O $SETTINGS https://github.com/bimberlabinternal/DevOps/raw/master/servers/mcc/${SETTINGS}

set -o allexport
source $SETTINGS
set +o allexport

if [ ! -e $LABKEY_HOME/labkey-tmp ];then
	mkdir -p $LABKEY_HOME/labkey-tmp
	chown -R $LABKEY_USER:$LABKEY_USER $LABKEY_HOME/labkey-tmp
fi

# Only populate from github when missing.  This allows one-off local edits
# Note: this needs to run before the actual server install below to take effect
CONFIGURATION_DIR=${LABKEY_HOME}/configuration
if [ ! -e $CONFIGURATION_DIR ];then
	mkdir -p $CONFIGURATION_DIR

	wget -O ${CONFIGURATION_DIR}/application.properties https://github.com/bimberlabinternal/DevOps/raw/master/servers/mcc/config/application.properties

	# Append private values:
	cat $CONFIGURATION_DIR/mcc.application.properties >> ${CONFIGURATION_DIR}/application.properties
	
	wget -O $CONFIGURATION_DIR/labkey_server.env https://github.com/bimberlabinternal/DevOps/raw/master/servers/mcc/config/labkey_server.env
	wget -O $CONFIGURATION_DIR/startup.sh https://github.com/bimberlabinternal/DevOps/raw/master/servers/mcc/config/startup.sh
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
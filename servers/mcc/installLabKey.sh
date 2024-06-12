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

# Only populate from github when missing.  This allows one-off local edits
# Note: this needs to run before the actual server install below to take effect
CONFIG_DIR=${LABKEY_HOME}/config
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR
	
	wget -O ${CONFIG_DIR}/application.properties https://github.com/bimberlabinternal/DevOps/raw/master/servers/mcc/config/application.properties
	
	# Append private values:
	cat ~/mcc.application.properties >> ${CONFIG_DIR}/application.properties
fi

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

rm $INSTALL
rm $SETTINGS
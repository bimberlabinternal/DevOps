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

# Only populate from github when missing.  This allows one-off local edits
# Note: this needs to run before the actual server install below to take effect
LK_CONFIG=/usr/local/etc/labkey
if [ ! -e $LK_CONFIG ];then
	mkdir -p $LK_CONFIG

	wget -O ${LK_CONFIG}/base.application.properties https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/config/application.properties

	wget -O $LK_CONFIG/labkey_server.env https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/config/labkey_server.env
	wget -O $LK_CONFIG/labkeyServerStartup.sh https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/config/labkeyServerStartup.sh
	chmod +x $LK_CONFIG/labkeyServerStartup.sh
fi

CONFIG_DIR=${LABKEY_HOME}/config
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR

	echo 'Creating application.properties'
	cat ${LK_CONFIG}/base.application.properties ${LK_CONFIG}/mcc.application.properties > ${CONFIG_DIR}/application.properties
fi

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

rm $INSTALL
rm $SETTINGS
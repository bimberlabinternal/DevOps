#!/bin/bash

#PRIMe-Seq:

set -x
set -e

SETTINGS=primeseqSettings.sh
if [ -e $SETTINGS ];then
	rm $SETTINGS
fi

wget -O $SETTINGS https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/${SETTINGS}

set -o allexport
source $SETTINGS
set +o allexport

# Only populate from github when missing.  This allows one-off local edits
# Note: this needs to run before the actual server install below to take effect
CONFIG_DIR=${LABKEY_HOME}/config
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR
	
	wget -O ${CONFIG_DIR}/sequenceanalysisConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/sequenceanalysisConfig.xml
	wget -O ${CONFIG_DIR}/pipelineConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/pipelineConfig.xml
	wget -O ${CONFIG_DIR}/blastConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/blastConfig.xml
	wget -O ${CONFIG_DIR}/ehrConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/ehrConfig.xml
	wget -O ${CONFIG_DIR}/jbrowseConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/jbrowseConfig.xml
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
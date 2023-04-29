#!/bin/bash

#Exacloud

set -x
set -e

SETTINGS=exacloudSettings.sh
if [ -e $SETTINGS ];then
	rm $SETTINGS
fi

wget -O $SETTINGS https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/${SETTINGS}

set -o allexport
source $SETTINGS
set +o allexport

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

rm $INSTALL

# Only populate from github when missing.  This allows one-off local edits
CONFIG_DIR=${LK_SRC_DIR}/config
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR
	
	wget -O ${CONFIG_DIR}/sequenceanalysisConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/sequenceanalysisConfig.xml
	wget -O ${CONFIG_DIR}/pipelineConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/pipelineConfig.xml
	wget -O ${CONFIG_DIR}/blastConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/blastConfig.xml
	wget -O ${CONFIG_DIR}/ehrConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/ehrConfig.xml
fi

JAVA_WRAPPER=${LK_SRC_DIR}/javaWrapper.sh
if [ ! -e $JAVA_WRAPPER ];then
	wget -O $JAVA_WRAPPER https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/javaWrapper.sh
	chmod +x $JAVA_WRAPPER
fi
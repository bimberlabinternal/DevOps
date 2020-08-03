#!/bin/sh

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
SKIP_INSTALL=1
set +o allexport

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

JAVA_WRAPPER=${LABKEY_HOME}/javaWrapper.sh
if [ -e $JAVA_WRAPPER ];then
	rm $JAVA_WRAPPER
fi

wget -O $JAVA_WRAPPER https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/${JAVA_WRAPPER}

rm $INSTALL

# Only populate from github when missing.  This allows one-off local edits
CONFIG_DIR=${LK_SRC_DIR}/config
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR
	
	wget -O sequenceanalysisConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/sequenceanalysisConfig.xml
	wget -O pipelineConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/pipelineConfig.xml
	wget -O blastConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/blastConfig.xml
fi

if [ ! -e javaWrapper.sh ];then
	wget -O javaWrapper.sh https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/javaWrapper.sh
	chmod +x javaWrapper.sh
fi
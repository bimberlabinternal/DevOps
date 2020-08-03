#!/bin/sh

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

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

rm $INSTALL
rm $SETTINGS

# Only populate from github when missing.  This allows one-off local edits
CONFIG_DIR=${LABKEY_HOME}/configs
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR
	
	wget -O ${CONFIG_DIR}/sequenceanalysisConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/configs/sequenceanalysisConfig.xml
	wget -O ${CONFIG_DIR}/pipelineConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/configs/pipelineConfig.xml
	wget -O ${CONFIG_DIR}/blastConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/mgap/configs/blastConfig.xml
fi

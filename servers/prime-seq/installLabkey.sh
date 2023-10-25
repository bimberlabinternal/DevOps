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
CONFIG_DIR=${LABKEY_HOME}/configs
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR
	
	wget -O ${CONFIG_DIR}/sequenceanalysisConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/configs/sequenceanalysisConfig.xml
	wget -O ${CONFIG_DIR}/pipelineConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/configs/pipelineConfig.xml
	wget -O ${CONFIG_DIR}/blastConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/configs/blastConfig.xml
	wget -O ${CONFIG_DIR}/ehrConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/ehrConfig.xml
	wget -O ${CONFIG_DIR}/jbrowseConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/jbrowseConfig.xml
fi

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

rm $INSTALL
rm $SETTINGS
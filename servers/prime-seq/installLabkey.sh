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
LK_CONFIG=/usr/local/etc/labkey
if [ ! -e $LK_CONFIG ];then
	mkdir -p $LK_CONFIG

	wget -O ${LK_CONFIG}/base.application.properties https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/application.properties

	wget -O $LK_CONFIG/labkey_server.env https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/labkey_server.env
	wget -O $LK_CONFIG/labkeyServerStartup.sh https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/labkeyServerStartup.sh
	chmod +x $LK_CONFIG/labkeyServerStartup.sh
fi

CONFIG_DIR=/usr/local/labkey/config
if [ ! -e $CONFIG_DIR ];then
	mkdir -p $CONFIG_DIR
	
	wget -O ${CONFIG_DIR}/sequenceanalysisConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/sequenceanalysisConfig.xml
	wget -O ${CONFIG_DIR}/pipelineConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/pipelineConfig.xml
	wget -O ${CONFIG_DIR}/blastConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/prime-seq/config/blastConfig.xml
	wget -O ${CONFIG_DIR}/ehrConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/ehrConfig.xml
	wget -O ${CONFIG_DIR}/jbrowseConfig.xml https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/config/jbrowseConfig.xml
	
	echo 'Creating application.properties'
	cat ${LK_CONFIG}/base.application.properties ${LK_CONFIG}/prime-seq.application.properties > ${CONFIG_DIR}/application.properties
fi

INSTALL=installLabkeyBase.sh
if [ -e $INSTALL ];then
	rm $INSTALL
fi

wget --no-cache -O $INSTALL https://github.com/bimberlabinternal/DevOps/raw/master/servers/installLabkeyBase.sh

bash $INSTALL $SETTINGS

rm $INSTALL
rm $SETTINGS

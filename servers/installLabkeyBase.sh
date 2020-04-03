#!/bin/sh
#
# This script is designed to upgrade LabKey on this server
# usage: ./installLabKey.sh ${distribution}
#

set -x
set -e


# A separate settings file should provide the following:
MAJOR=20
MINOR_FULL="3"
MINOR_SHORT=3
ARTIFACT=LabKey${MAJOR}.${MINOR_FULL}Beta
LKENV=$(grep ^EnvironmentFile /etc/systemd/system/labkey.service | cut -d = -f2 | sed 's/ //g')
TOMCAT_HOME=$(grep ^CATALINA_HOME $LKENV | cut -d= -f2 | sed 's/ //g')
SKIP_INSTALL=
TEAMCITY_USERNAME=bbimber

SETTINGS_FILE=$1
if [ ! -e $SETTINGS_FILE ];then
    echo 'Missing settings file: '$SETTINGS_FILE
    exit 1
fi

source $SETTINGS_FILE

if [ -z $MAJOR ];then
    echo 'Need to set environment variable MAJOR'
    exit 1
fi

if [ -z $MINOR_FULL ];then
    echo 'Need to set environment variable MINOR_FULL'
    exit 1
fi

if [ -z $MINOR_SHORT ];then
    echo 'Need to set environment variable MINOR_SHORT'
    exit 1
fi

if [ -z $ARTIFACT ];then
    echo 'Need to set environment variable ARTIFACT'
    exit 1
fi

if [ -z $TOMCAT_HOME ];then
    echo 'Need to set environment variable TOMCAT_HOME'
    exit 1
fi

#Note: use .netrc to set password
if [ -z $TEAMCITY_USERNAME ];then
    echo 'Need to set environment variable TEAMCITY_USERNAME'
    exit 1
fi

if [ -z $LABKEY_HOME ];then
    LABKEY_HOME=/usr/local/labkey
fi

if [ -z $LABKEY_USER ];then
    LABKEY_USER=labkey
fi

BRANCH=LabKey_Discvr_Discvr${MAJOR}${MINOR_SHORT}_Premium_Installers
MODULE_DIST_NAME=prime-seq-modules
PREMIUM=premium-${MAJOR}.${MINOR_SHORT}.module
DATAINTEGRATION=dataintegration-${MAJOR}.${MINOR_SHORT}.module
LDAP=ldap-${MAJOR}.${MINOR_SHORT}.module

isGzOrZip() {
	RET=`file $1 | grep -E 'gzip compressed|Zip archive data' | wc -l`
	if [ $RET == 0 ];then
		echo "Not GZIP!"
		exit 1
	else
		echo "Is GZIP!"
	fi
}

#first download
DATE=$(date +"%Y%m%d%H%M")
MODULE_ZIP=${ARTIFACT}-ExtraModules-${DATE}.zip
rm -Rf $MODULE_ZIP
wget -O $MODULE_ZIP https://${TEAMCITY_USERNAME}@teamcity.labkey.org/repository/download/${BRANCH}/.lastSuccessful/${MODULE_DIST_NAME}/${ARTIFACT}-{build.number}-ExtraModules.zip
isGzOrZip $MODULE_ZIP

GZ=${ARTIFACT}-${DATE}-discvr-bin.tar.gz
rm -Rf $GZ
wget -O $GZ https://${TEAMCITY_USERNAME}@teamcity.labkey.org/repository/download/${BRANCH}/.lastSuccessful/discvr/${ARTIFACT}-{build.number}-discvr-bin.tar.gz
isGzOrZip $GZ

#extract, find name
tar -xf $GZ
DIR=$(ls -tr | grep "^${ARTIFACT}*" | grep 'discvr-bin$' | tail -n -1)
echo "DIR: $DIR"
BASENAME=$(echo ${DIR} | sed 's/-discvr-bin//')
mv $GZ ./${BASENAME}-discvr-bin.tar.gz
mv $MODULE_ZIP ./${BASENAME}-ExtraModules.zip
GZ=${BASENAME}-discvr-bin.tar.gz
MODULE_ZIP=${BASENAME}-ExtraModules.zip

#premium
if [ ! -e $PREMIUM ];then
    echo 'Not found: '$PREMIUM
    exit 1
fi

#DataIntegration
if [ ! -e $DATAINTEGRATION ];then
    echo 'Not found: '$DATAINTEGRATION
    exit 1
fi

#LDAP
if [ ! -e $LDAP ];then
    echo 'Not found: '$LDAP
    exit 1
fi

if [ -z $SKIP_INSTALL ];then
    echo "Begin install"

    systemctl stop labkey.service

    #extra modules first
    rm -Rf ${LABKEY_HOME}/externalModules
    mkdir -p ${LABKEY_HOME}/externalModules
    chown -R labkey:labkey ${LABKEY_HOME}/externalModules
    rm -Rf modules_unzip
    unzip $MODULE_ZIP -d ./modules_unzip
    MODULE_DIR=$(ls ./modules_unzip | tail -n -1)
    echo $MODULE_DIR
    cp ./modules_unzip/${MODULE_DIR}/modules/*.module ${LABKEY_HOME}/externalModules
    rm -Rf ./modules_unzip

    cp $PREMIUM ${LABKEY_HOME}/externalModules
    cp $DATAINTEGRATION ${LABKEY_HOME}/externalModules
    cp $LDAP ${LABKEY_HOME}/externalModules

    #main server
    echo "Installing LabKey using: $GZ"
    cd $DIR
    ./manual-upgrade.sh -u $LABKEY_USER -c $TOMCAT_HOME -l $LABKEY_HOME --noPrompt
    cd ../
    systemctl start labkey.service
else
    echo 'Skipping install'
fi

# clean up
echo "Removing folder: $DIR"
rm -Rf $DIR

echo "cleaning up installers, leaving 5 most recent"
ls -tr | grep "^${ARTIFACT}.*\.gz$" | head -n -5 | xargs rm

echo "cleaning up ZIP, leaving 5 most recent"
ls -tr | grep "^${ARTIFACT}.*\.zip$" | head -n -5 | xargs rm
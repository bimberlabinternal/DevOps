#!/bin/bash
#
# This script is designed to upgrade LabKey on this server
# usage: ./installLabKey.sh ${distribution}
#

set -x
set -e

# A separate settings file should provide the following:
#MAJOR=20
#MINOR_FULL="7"
#MINOR_SHORT=7
#TOMCAT_HOME=XXXX

TC_PROJECT=LabKey_${MAJOR}${MINOR_FULL}Release_External_Discvr_Installers
ARTIFACT=LabKey${MAJOR}.${MINOR_FULL}-SNAPSHOT

SKIP_INSTALL=
TEAMCITY_USERNAME=bbimber
MODULE_DIST_NAME=prime-seq-modules

SETTINGS_FILE=$1
if [ ! -e $SETTINGS_FILE ];then
	echo 'Missing settings file: '$SETTINGS_FILE
	exit 1
fi

set -o allexport
source $SETTINGS_FILE
set +o allexport

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
GZ=Temp-${ARTIFACT}-${DATE}-discvr.tar.gz
rm -Rf $GZ
wget --no-check-certificate -O $GZ https://${TEAMCITY_USERNAME}@teamcity.labkey.org/repository/download/${TC_PROJECT}/.lastSuccessful/prime-seq/${ARTIFACT}-{build.number}-prime-seq.embedded.tar.gz
isGzOrZip $GZ

#extract, find name
tar -xf $GZ
DIR=$(ls -tr | grep "^${ARTIFACT}*" | grep 'discvr$' | tail -n -1)
echo "DIR: $DIR"
if [ -z $DIR ];then
	echo 'There was an error parsing the output folder name'
	exit 1
fi

BASENAME=$ARTIFACT

mv $GZ ./${BASENAME}-discvr.tar.gz
GZ=${BASENAME}-discvr.tar.gz

if [ -z $SKIP_INSTALL ];then
	echo "Begin install"

	systemctl stop labkey.service

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

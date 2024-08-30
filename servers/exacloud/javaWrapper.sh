#!/bin/bash

# this script is used to wrap the cluster java process for OHSU/exacloud
# the purpose is to:
# 1) set umask to 0002
# 2) if an incoming job uses the WEEK_LONG_JOB flag, instead of using the core LK install dir, we
# make a local copy for this job.  this means we can more easily push out new builds while these long jobs are running
# 3) if  an incoming job uses the WEEK_LONG_JOB flag, we also make an alternate TEMP directory on lustre (the default is the node's local disk)
# and change the stripe

set -e
set -u
set -x

export BCFTOOLS_PLUGINS=/home/exacloud/gscratch/prime-seq/bin/bcftools_plugins

# Added for GATK tools:
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

finish() {
	EXIT_CODE=$?
	echo "Finalizing job, java exit code: "$EXIT_CODE
	
	if [ $EXIT_CODE != 0 ];then
		echo "ERROR RUNNING JOB"
	fi
	
	if [ ! -z "${TEMP_DIR-}" ];then
		rm -Rf $TEMP_DIR
	fi
	
	if [ ! -z "${LOCAL_TEMP_LK-}" ];then
		if [ -e $LOCAL_TEMP_LK ];then
			rm -Rf $LOCAL_TEMP_LK
		fi
	fi
	
	if [ ! -z "${LABKEY_HOME_LOCAL-}" ];then
		if [ -e $LABKEY_HOME_LOCAL ];then
			rm -Rf $LABKEY_HOME_LOCAL
		fi
	fi
	
	exit $EXIT_CODE
}

trap finish SIGTERM SIGKILL SIGINT SIGHUP EXIT SIGQUIT

#Basic job info:
hostname
echo $SLURM_JOBID

# Ensure NFS mounts exist:
if [ ! -w /home/groups/prime-seq/production/ ];then
	echo '/home/groups/prime-seq/production/ not writable!'
	ls -lah /home/groups/prime-seq/production/
	exit 1
fi

SCRIPT_DIR=`dirname "$0"`
SETTINGS=${SCRIPT_DIR}/exacloudSettings.sh
if [ ! -e $SETTINGS ];then
	echo "Settings files not found: "${SETTINGS}
	exit 1
fi

set -o allexport
source $SETTINGS
set +o allexport

# This should be provided by $SETTINGS
if [ ! -e $JAVA ];then
	echo "java executable not found: "$JAVA	
	exit 1
fi

$JAVA -version

GZ_PREFIX=LabKey${MAJOR}.${MINOR_FULL}
TOOL_DIR=/home/exacloud/gscratch/prime-seq/bin/

ORIG_WORK_DIR=$(pwd)

#Allow this to be overridden in environment
if [[ ! -v WORK_BASEDIR ]];then
	WORK_BASEDIR=/home/exacloud/gscratch/prime-seq/workDir/
fi

# Note: Use local scratch rather than lustre:
TEMP_BASEDIR=/mnt/scratch

TEMP_BASEDIR=$TEMP_BASEDIR/prime-seq
if [ ! -e $TEMP_BASEDIR ];then
	mkdir -p $TEMP_BASEDIR
fi

export PATH=${JAVA_HOME}/bin/:$TOOL_DIR:$PATH

umask 0006

JOB_FILE="${!#}"
JOB_FILE="${JOB_FILE//file:/}"

BASENAME=`basename "$JOB_FILE" '.job.json.txt'`

#make new temp directory, specifically for the job's output.  i think deleting the general temp dir while this script and LK are running might be an issue
TEMP_DIR=`mktemp -d --tmpdir=$TEMP_BASEDIR --suffix=${BASENAME}`
echo $TEMP_DIR

WORK_DIR=$WORK_BASEDIR
echo $WORK_DIR

LOCAL_TEMP_LK=`mktemp -d --tmpdir=/tmp --suffix=$BASENAME`
echo $LOCAL_TEMP_LK

mkdir -p $TEMP_DIR
mkdir -p $LOCAL_TEMP_LK

export TEMP_DIR=$TEMP_DIR
export TMPDIR=$TEMP_DIR
export TMP=$TEMP_DIR
export TEMP=$TEMP_DIR

#this should let us verify the above worked
LABKEY_HOME_LOCAL=${LOCAL_TEMP_LK}/labkey
if [ -e $LABKEY_HOME_LOCAL ];then
	rm -Rf $LABKEY_HOME_LOCAL
fi

if [ ! -e $LK_SRC_DIR/config ];then
	echo "Config dir not found: $LK_SRC_DIR/config"
	exit 1
fi

#Main server:
SERVER_JAR=${LK_SRC_DIR}/labkeyServer.jar
if [ ! -e $SERVER_JAR ];then
	echo "Server JAR not found: $SERVER_JAR"
	exit 1
fi

#copy relevant code locally
mkdir -p $LABKEY_HOME_LOCAL
cd $LABKEY_HOME_LOCAL
cp $SERVER_JAR ./
$JAVA -jar labkeyServer.jar -extract
cp -R $LK_SRC_DIR/config ./
cd $TEMP_BASEDIR

#edit arguments
updatedArgs=( "$@" )
for(( a=0; a<${#updatedArgs[@]}-1 ;a++ ));  do
	arg="${updatedArgs[$a]}"
	#echo $arg

	#if matches origial dir, replace path
	TO_SUB=$LK_SRC_DIR
	updatedArgs[$a]="${arg//$TO_SUB/$LABKEY_HOME_LOCAL}"
done

#add -Djava.io.tmpdir
ESCAPE=$(echo $TEMP_DIR | sed 's/\//\\\//g')
sed -i 's/<!--<entry key="JAVA_TMP_DIR" value=""\/>-->/<entry key="JAVA_TMP_DIR" value="'$ESCAPE'"\/>/g' ${LABKEY_HOME_LOCAL}/config/pipelineConfig.xml

ESCAPE=$(echo $WORK_DIR | sed 's/\//\\\//g')
sed -i 's/WORK_DIR/'$ESCAPE'/g' ${LABKEY_HOME_LOCAL}/config/pipelineConfig.xml

# See here for rationale behind --add-opens arguments:
# https://www.labkey.org/Documentation/wiki-page.view?name=supported
$JAVA -XX:HeapBaseMinAddress=4294967296 \
	-Djava.io.tmpdir=${TEMP_DIR} \
	--add-opens=java.base/java.lang=ALL-UNNAMED \
	--add-opens=java.base/java.io=ALL-UNNAMED \
	--add-opens=java.base/java.util=ALL-UNNAMED \
	--add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
	--add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED \
	--add-opens=java.base/java.text=ALL-UNNAMED \
	--add-opens=java.desktop/java.awt.font=ALL-UNNAMED \
	${updatedArgs[@]}
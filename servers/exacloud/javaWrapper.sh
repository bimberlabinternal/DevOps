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

finish() {
	EXIT_CODE=$?
	if [ $EXIT_CODE != 0 ];then
		echo "ERROR RUNNING JOB"
		#ps -e -T -o pid,lwp,pri,nice,start,stat,bsdtime,cmd,comm,user
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

# Note: this is a separate RDS dataset mounted within the prime-seq tree:
#CHECK_204=`df /home/groups/prime-seq/production/Internal/ColonyData/204/@files | grep -e 'MgapGenomicsDb' | wc -l`
#if [ $CHECK_204 != '1' ];then
#	echo 'Improper mount for: workbook 204'
#	df /home/groups/prime-seq/production/Internal/ColonyData/204/@files
#	exit 1
#fi

CHECK_51=`df -h /home/groups/prime-seq/production/Internal/ColonyData/51 | grep 51 | wc -l`
if [ $CHECK_51 != '1' ];then
	echo 'Improper mount for: workbook 51'
	df /home/groups/prime-seq/production/Internal/ColonyData/51
	exit 1
fi

CHECK_121=`df -h /home/groups/prime-seq/production/Internal/ColonyData/121 | grep 121 | wc -l`
if [ $CHECK_121 != '1' ];then
	echo 'Improper mount for: workbook 121'
	df /home/groups/prime-seq/production/Internal/ColonyData/121
	exit 1
fi

if [ ! -w /home/groups/prime-seq/production/ ];then
	echo '/home/groups/prime-seq/production/ not writable!'
	ls -lah df /home/groups/prime-seq/production/
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

GZ_PREFIX=LabKey${MAJOR}.${MINOR_FULL}
TOOL_DIR=/home/exacloud/gscratch/prime-seq/bin/

ORIG_WORK_DIR=$(pwd)

#Allow this to be overridden in environment
if [[ ! -v WORK_BASEDIR ]];then
	WORK_BASEDIR=/home/exacloud/gscratch/prime-seq/workDir/
fi

if [[ ! -v USE_LUSTRE ]];then
	USE_LUSTRE=0
fi

if [ $USE_LUSTRE == 1 ];then
	echo 'using old lustre'
	WORK_BASEDIR=/home/exacloud/lustre1/prime-seq/workDir/
fi

#Note: this used to use lustre space; however, now use local scratch
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

#If temp directory is on lustre:
if [[ $TEMP_DIR =~ "/home/exacloud/lustre1" ]];then
	lfs setstripe -c 1 $TEMP_DIR
fi

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

mkdir -p $LABKEY_HOME_LOCAL

#copy relevant code locally
cd $LABKEY_HOME_LOCAL

#Main server:
GZ=$(ls -tr $LK_SRC_DIR | grep "^${GZ_PREFIX}.*-discvr\.tar\.gz$" | tail -n -1)
cp ${LK_SRC_DIR}/$GZ ./
GZ=$(basename $GZ)
echo "TAR: $GZ"
tar -xf $GZ

# NOTE: the name of the directory within this archive is not predictable based on TAR name. 
# The rationale is to take the last (newest) directory matching this name. 
DIR=$(find . -maxdepth 1 -type d | grep "./${GZ_PREFIX}-*" | tail -n -1)
echo "DIR: $DIR"

cd $DIR

export TOMCAT_HOME=${LABKEY_HOME_LOCAL}/tomcat

mkdir -p $TOMCAT_HOME
mkdir -p $TOMCAT_HOME/lib

./manual-upgrade.sh -u $LABKEY_USER -c $TOMCAT_HOME -l $LABKEY_HOME_LOCAL --noPrompt --skip_tomcat

if [ ! -e $TOMCAT_HOME/lib/labkeyBootstrap.jar ];then
	echo "Unable to find $TOMCAT_HOME/lib/labkeyBootstrap.jar"
	exit 1
fi
cp $TOMCAT_HOME/lib/labkeyBootstrap.jar $LABKEY_HOME_LOCAL/labkeyBootstrap.jar

#Extra modules:
MODULE_ZIP=$(ls -tr $LK_SRC_DIR | grep "^${GZ_PREFIX}.*-ExtraModules\.zip$" | tail -n -1)
if [ -e modules_unzip ];then
	rm -Rf modules_unzip
fi
cp ${LK_SRC_DIR}/$MODULE_ZIP ./
MODULE_ZIP=$(basename $MODULE_ZIP)
unzip $MODULE_ZIP -d ./modules_unzip
MODULE_DIR=$(ls ./modules_unzip | tail -n -1)
cp ./modules_unzip/${MODULE_DIR}/modules/*.module ${LABKEY_HOME_LOCAL}/modules
rm -Rf ./modules_unzip
rm -Rf $MODULE_ZIP

#Config:
cp -R $LK_SRC_DIR/config $LABKEY_HOME_LOCAL

cd "$ORIG_WORK_DIR"
rm -Rf $DIR

#edit arguments
updatedArgs=( "$@" )
for(( a=0; a<${#updatedArgs[@]}-1 ;a++ ));  do
	arg="${updatedArgs[$a]}"
	#echo $arg

	#if matches origial dir, replace path
	TO_SUB=$LK_SRC_DIR
	updatedArgs[$a]="${arg//$TO_SUB/$LABKEY_HOME_LOCAL}"
done

#also add /externalModules
#lastArg=${updatedArgs[${#updatedArgs[@]} - 1]}
#updatedArgs[${#updatedArgs[@]} - 1]="-Dlabkey.externalModulesDir="${LABKEY_HOME_LOCAL}"/externalModules"
#updatedArgs[${#updatedArgs[@]}]=$lastArg

#add -Djava.io.tmpdir
ESCAPE=$(echo $TEMP_DIR | sed 's/\//\\\//g')
sed -i 's/<!--<entry key="JAVA_TMP_DIR" value=""\/>-->/<entry key="JAVA_TMP_DIR" value="'$ESCAPE'"\/>/g' ${LABKEY_HOME_LOCAL}/config/pipelineConfig.xml
ESCAPE=$(echo $WORK_DIR | sed 's/\//\\\//g')	
sed -i 's/WORK_DIR/'$ESCAPE'/g' ${LABKEY_HOME_LOCAL}/config/pipelineConfig.xml

if [ $USE_LUSTRE == 1 ];then
	echo 'swapping gscratch for lustre1 in XML file'
	sed -i 's/exacloud\/gscratch/exacloud\/lustre1/g' ${LABKEY_HOME_LOCAL}/config/pipelineConfig.xml
fi

# Quote the last arg, which is the file path:
updatedArgs[$a]="\""${updatedArgs[$a]}"\""

$JAVA -XX:HeapBaseMinAddress=4294967296 -Djava.io.tmpdir=${TEMP_DIR} ${updatedArgs[@]}

if [ ! -z $SLURM_JOBID ];then
	sacct -o reqmem,maxrss,averss,elapsed,cputime,alloccpus -j $SLURM_JOBID
fi

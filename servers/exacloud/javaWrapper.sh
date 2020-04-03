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

echo $SLURM_JOBID
hostname

SETTINGS=exacloudSettings.sh
if [ -e $SETTINGS ];then
	rm $SETTINGS
fi

wget -O $SETTINGS https://github.com/bimberlabinternal/DevOps/raw/master/servers/exacloud/${SETTINGS}

set -o allexport
source $SETTINGS
SKIP_INSTALL=1
set +o allexport

GZ_PREFIX=LabKey${MAJOR}.${MINOR_FULL}

ORIG_WORK_DIR=$(pwd)

#Allow this to be overridden in environment
if [[ ! -v WORK_BASEDIR ]];then
	WORK_BASEDIR=/home/exacloud/lustre1/prime-seq/workDir/
fi

PREMIUM=${LK_SRC_DIR}/premium-${MAJOR}.${MINOR_SHORT}.module
DATAINTEGRATION=${LK_SRC_DIR}/dataintegration-${MAJOR}.${MINOR_SHORT}.module

if [ ! -e $PREMIUM ];then
	exit 1;
fi

if [ ! -e $DATAINTEGRATION ];then
	exit 1;
fi

#Note: this used to use lustre space; however, now use local scratch
#TEMP_BASEDIR=/home/exacloud/lustre1/prime-seq/tempDir
TEMP_BASEDIR=/mnt/scratch

TEMP_BASEDIR=$TEMP_BASEDIR/prime-seq
if [ ! -e $TEMP_BASEDIR ];then
	mkdir -p $TEMP_BASEDIR
fi

export PATH=${JAVA_HOME}/bin/:/home/groups/prime-seq/pipeline_tools/bin:$PATH

umask 0006

JOB_FILE=${!#}
JOB_FILE=${JOB_FILE//file:/}

BASENAME=`basename $JOB_FILE '.job.json.txt'`

#make new temp directory, specifically for the job's output.  i think deleting the general temp dir while this script and LK are running might be an issue
TEMP_DIR=`mktemp -d --tmpdir=$TEMP_BASEDIR --suffix=${BASENAME}`
echo $TEMP_DIR

WORK_DIR=$WORK_BASEDIR
echo $WORK_DIR

LOCAL_TEMP_LK=`mktemp -d --tmpdir=/tmp --suffix=$BASENAME`
echo $LOCAL_TEMP_LK

function finish {
    echo "cleaning up temp dir"
    rm -Rf $TEMP_DIR
    if [ -e $LOCAL_TEMP_LK ];then
        rm -Rf $LOCAL_TEMP_LK
    fi

    if [ -e $LABKEY_HOME ];then
        rm -Rf $LABKEY_HOME
    fi
}

trap finish SIGTERM SIGKILL SIGINT SIGHUP EXIT SIGQUIT

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
LABKEY_HOME=${LOCAL_TEMP_LK}/labkey
if [ -e $LABKEY_HOME ];then
	rm -Rf $LABKEY_HOME
fi

mkdir -p $LABKEY_HOME

#try/catch/finally
{
	#copy relevant code locally
	cd $LABKEY_HOME
	
	MODULE_ZIP=$(ls -tr $LK_SRC_DIR | grep "^${GZ_PREFIX}.*\.zip$" | tail -n -1)
	rm -Rf ${LABKEY_HOME}/externalModules
	mkdir -p ${LABKEY_HOME}/externalModules
	if [ -e modules_unzip ];then
		rm -Rf modules_unzip
	fi

	cp ${LK_SRC_DIR}/$MODULE_ZIP ./
	MODULE_ZIP=$(basename $MODULE_ZIP)
	unzip $MODULE_ZIP -d ./modules_unzip
	MODULE_DIR=$(ls ./modules_unzip | tail -n -1)
	cp ./modules_unzip/${MODULE_DIR}/modules/*.module ${LABKEY_HOME}/externalModules
	rm -Rf ./modules_unzip
	rm -Rf $MODULE_ZIP

	cp $PREMIUM ${LABKEY_HOME}/externalModules/premium-${MAJOR}.${MINOR_FULL}.module
	cp $DATAINTEGRATION ${LABKEY_HOME}/externalModules/dataintegration-${MAJOR}.${MINOR_FULL}.module

	GZ=$(ls -tr $LK_SRC_DIR | grep "^${GZ_PREFIX}.*\.gz$" | tail -n -1)
	cp ${LK_SRC_DIR}/$GZ ./
	GZ=$(basename $GZ)
	gunzip $GZ
	TAR=`echo $GZ | sed -e "s/.gz$//"`
	echo "TAR: $TAR"
	tar -xf $TAR
	DIR=`echo $TAR | sed -e "s/.tar$//"`
	echo "DIR: $DIR"
	cd $DIR

	./manual-upgrade.sh -u $LABKEY_USER -c $TOMCAT_HOME -l $LABKEY_HOME --noPrompt --skip_tomcat

	cp -R $LK_SRC_DIR/config $LABKEY_HOME
	if [ $? != 0 ]; then print_error; fi # exit if the last command failed

	cd $ORIG_WORK_DIR
	rm -Rf $DIR
	rm -Rf $TAR

	#edit arguments
	updatedArgs=( "$@" )
	for(( a=0; a<${#updatedArgs[@]}-1 ;a++ ));  do
		arg=${updatedArgs[$a]}
		#echo $arg

		#if matches origial dir, replace path
		TO_SUB=$LK_SRC_DIR
		updatedArgs[$a]=${arg//$TO_SUB/$LABKEY_HOME}
	done

	#also add /externalModules
	lastArg=${updatedArgs[${#updatedArgs[@]} - 1]}
	updatedArgs[${#updatedArgs[@]} - 1]="-Dlabkey.externalModulesDir="${LABKEY_HOME}"/externalModules"
	updatedArgs[${#updatedArgs[@]}]=$lastArg

	#add -Djava.io.tmpdir
	ESCAPE=$(echo $TEMP_DIR | sed 's/\//\\\//g')
	sed -i 's/<!--<entry key="JAVA_TMP_DIR" value=""\/>-->/<entry key="JAVA_TMP_DIR" value="'$ESCAPE'"\/>/g' ${LABKEY_HOME}/config/pipelineConfig.xml
	ESCAPE=$(echo $WORK_DIR | sed 's/\//\\\//g')
	sed -i 's/WORK_DIR/'$ESCAPE'/g' ${LABKEY_HOME}/config/pipelineConfig.xml

	$JAVA -XX:HeapBaseMinAddress=4294967296 -verbose:class -Djava.io.tmpdir=${TEMP_DIR} ${updatedArgs[@]}

	if [ ! -z $SLURM_JOBID ];then
		sacct -o reqmem,maxrss,averss,elapsed,cputime,alloccpus -j $SLURM_JOBID
	fi
} || {
	echo "ERROR RUNNING JOB"
	ps -e -T -o pid,lwp,pri,nice,start,stat,bsdtime,cmd,comm,user
}
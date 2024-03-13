#!/bin/bash

set -e

if [[ -z $1 ]];then
	echo 'Must provide novogene project'
 	exit 1
fi

if [[ -z $2 ]];then
	echo 'Must provide password'
 	exit 1
fi

if [[ -z $3 ]];then
	echo 'Must provide expt'
 	exit 1
fi

if [ ! -e $DIRNAME ];then
	mkdir $DIRNAME
fi

cd $DIRNAME

PWD=`pwd`

#SCRIPT=${1}.sh
#wget -O $SCRIPT https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/downloadNovogeneScript.sh

sbatch \
	--job-name=$1 \
	--mem 8000 \
	--cpus-per-task=8 \
	--output=${1}.log \
	--error=${1}.log \
	--partition=exacloud \
	--time=0-36 \
	--chdir=$PWD \
	~/bin/downloadNovogeneScript.sh $1 $2 $3
#!/bin/bash

set -e

if [[ -z $1 ]];then
	echo "Must provide novogene project"
	exit 1
fi

SCRIPT=${1}.sh
PWD=`pwd`

wget -O $SCRIPT https://raw.githubusercontent.com/bimberlabinternal/DevOps/master/scripts/downloadNovogeneScript.sh

sbatch \
	--job-name=$1 \
	--mem 8000 \
	--cpus-per-task=8
	--output=${1}.log \
	--error=${1}.log \
	--partition=exacloud \
	--time=0-36 \
	--chdir=$PWD
#!/bin/bash

set -e

DIRNAME=$1
PW=$2
EXPT=$3

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

HOST=128.120.88.245
wget -q -r -c --password=${PW} --reject-regex="_I1_|_I2_|Undetermined_" ftp://${DIRNAME}@${HOST}:21/
touch download.${DIRNAME}.done
find . -name '*.gz' -exec mv {} ./ \;

if ls Undetermined_* 1> /dev/null 2>&1; then
	rm Undetermined_*
fi

if ls *_I1_* 1> /dev/null 2>&1; then
	rm *_I1_*
fi

if ls *_I2_* 1> /dev/null 2>&1; then
	rm *_I2_*
fi

cd ../
mv $DIRNAME /home/groups/BimberLab/primeseq/${EXPT}/@files/

echo 'done: '$DIRNAME

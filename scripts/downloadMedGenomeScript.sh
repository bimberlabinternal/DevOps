#!/bin/bash

set -e

DIRNAME=$1
PW=$2

if [[ -z $1 ]];then
	echo 'Must provide MedGenome project'
 	exit 1
fi

if [[ -z $2 ]];then
	echo 'Must provide password'
 	exit 1
fi

if [[ ! -z $3 ]];then
	EXPT=$3
	echo "Expt: "$EXPT
fi

if [ ! -e $DIRNAME ];then
	mkdir $DIRNAME
fi

cd $DIRNAME

HOST=portal-us.medgenome.com
wget -nv -r -c --no-check-certificate --user= --password=${PW} --cut-dirs=1 --reject "index.html*" --reject-regex="_I1_|_I2_|Undetermined_" https://${HOST}/${USER}/FASTQ
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

echo 'File size:'
du -s -h ../$DIRNAME

if [[ ! -z $3 ]];then
	echo "Copying data"
	cd ../
	mv $DIRNAME /home/groups/BimberLab/primeseq/${EXPT}/@files/
	touch /home/groups/BimberLab/primeseq/${EXPT}/@files/${DIRNAME}/move.${DIRNAME}.done
else
	echo "Experiment not provided, will not move"
fi

echo 'done: '$DIRNAME

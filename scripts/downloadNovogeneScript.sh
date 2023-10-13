#!/bin/bash

set -e

DIRNAME=$1
PW=$2

if [ ! -e $DIRNAME ];then
	mkdir $DIRNAME
fi

cd $DIRNAME

HOST=128.120.88.245
wget -r -c --http-password=${PW} --reject-regex="_I1_|_I2_|Undetermined_" ftp://${DIRNAME}@${HOST}:21/
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

echo 'done: '$DIRNAME

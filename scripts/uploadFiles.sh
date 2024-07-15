#!/bin/bash


set -e
set -x

FILE=$1
SUBMISSION=$2
DIR=$3
SCRIPT=uploadFile.sh

while read p; do
	bash $SCRIPT "${DIR}$p" $SUBMISSION
done < $FILE

echo 'Done'
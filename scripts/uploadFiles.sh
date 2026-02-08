#!/bin/bash

set -e
set -x

if [[ ! -n "$NCBI_ID" ]]; then
	echo "Variable NCBI_ID is unset or empty"
	exit 1
fi

if [[ ! -n "$KEY_FILE" ]]; then
	echo "Variable KEY_FILE is unset or empty"
	exit 1
fi

FILE=$1
SUBMISSION=$2
DIR=$3
SCRIPT=uploadFile.sh

while read p; do
	bash $SCRIPT "${DIR}$p" $SUBMISSION
done < $FILE

echo 'Done'
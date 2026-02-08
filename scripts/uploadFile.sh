#!/bin/bash

set -x

# wget https://download.asperasoft.com/download/sw/connect/3.9.8/ibm-aspera-connect-3.9.8.176272-linux-g2.12-64.tar.gz

FILE=$1
DONE_FILE=${FILE}.done
SUBMISSION=$2

ASCP=~/.aspera/connect/bin/ascp

if [[ ! -n "$NCBI_ID" ]]; then
	echo "Variable NCBI_ID is unset or empty"
	exit 1
fi

if [[ ! -n "$KEY_FILE" ]]; then
	echo "Variable KEY_FILE is unset or empty"
	exit 1
fi

export PATH=~/.aspera/connect/bin/:$PATH
echo 'Starting file: '$FILE

function retry {
	command="$*"
	retval=1
	attempt=1
	until [[ $retval -eq 0 ]] || [[ $attempt -gt 5 ]]; do
		# Execute inside of a subshell in case parent
		# script is running with "set -e"
		(
			set +e
			$command
		)
		retval=$?
		attempt=$(( $attempt + 1 ))
		if [[ $retval -ne 0 ]]; then
			# If there was an error wait 10 seconds
			sleep 10
		fi
	done
	if [[ $retval -ne 0 ]] && [[ $attempt -gt 5 ]]; then
		exit $retval
	fi
}

if [ ! -e $DONE_FILE ];then
	#NOTE: -k0 can be used to force re-upload. k1 allows resume
	retry $ASCP -i $KEY_FILE -QT -l300m -k0 -d $FILE subasp@upload.ncbi.nlm.nih.gov:uploads/$NCBI_ID/$SUBMISSION/
	touch $DONE_FILE
else
	echo 'Transfer already complete'
fi


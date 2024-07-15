#!/bin/bash

set -e
set -x

# wget https://download.asperasoft.com/download/sw/connect/3.9.8/ibm-aspera-connect-3.9.8.176272-linux-g2.12-64.tar.gz

FILE=$1
DONE_FILE=${FILE}.done
SUBMISSION=$2

ASCP=~/.aspera/connect/bin/ascp
KEY_FILE=./aspera.openssh
ASPERA_SCP_PASS=$KEY_FILE

export PATH=~/.aspera/connect/bin/:$PATH
echo 'Starting file: '$FILE

if [ ! -e $DONE_FILE ];then
	#NOTE: -k0 can be used to force re-upload. k1 allows resume
	$ASCP -i $KEY_FILE -QT -l300m -k0 -d $FILE subasp@upload.ncbi.nlm.nih.gov:uploads/bbimber@gmail.com_oceqPdPd/$SUBMISSION/
	touch $DONE_FILE
else
	echo 'Transfer already complete'
fi


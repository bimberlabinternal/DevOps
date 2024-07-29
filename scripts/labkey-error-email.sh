#!/bin/sh

LABKEY_HOME=/usr/local/labkey

LAST_LOG=/var/log/labkey-errors.log.last
OFFSET=1
if [ -e $LAST_LOG ];then
	OFFSET=`cat $LAST_LOG | wc -l`
	OFFSET=$((OFFSET+1))
fi

cp ${LABKEY_HOME}/logs/labkey-errors.log $LAST_LOG

TEMP_FILE=`mktemp`
/usr/bin/tail -n +${OFFSET} $LAST_LOG | grep -v 'Password reset attempted' | /usr/local/tools/filterLogMessages.py > $TEMP_FILE

LC=`cat $TEMP_FILE | wc -l`
if [[ $LC > 0 ]];then
	SERVER_NAME=`hostname`
	cat $TEMP_FILE | mail -s $SERVER_NAME' error log change' bimber@ohsu.edu
fi

rm $TEMP_FILE
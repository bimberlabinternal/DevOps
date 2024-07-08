#!/bin/sh

LABKEY_HOME=/usr/local/labkey

LAST_LOG=/var/log/labkey-errors.log.last
OFFSET=1
if [ -e $LAST_LOG ];then
        OFFSET=`cat $LAST_LOG | wc -l`
fi

cp ${LABKEY_HOME}/logs/labkey-errors.log $LAST_LOG

/usr/bin/tail -n +${OFFSET} $LAST_LOG | grep -v 'Password reset attempted' > /tmp/lk-errors.tmp

LC=`cat $LAST_LOG | wc -l`
if [[ $LC > 0 ]];then
	SERVER_NAME=`hostname`
	cat /tmp/lk-errors.tmp | mail -s $SERVER_NAME' error log change' bimber@ohsu.edu
fi

rm /tmp/lk-errors.tmp
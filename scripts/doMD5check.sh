#!/bin/bash

set -e 
set -x

EXPECTED=`cat md5sum.txt | wc -l`
ACTUAL=`find . -name '*.gz' | wc -l`

if [ $EXPECTED != $ACTUAL ];then
	echo "Missing files: $EXPECTED / $ACTUAL"
	exit 1
fi

cat md5sum.txt | grep -v '_I' > md5sum2.txt

md5sum -c md5sum2.txt | tee md5results.txt

chmod +x ../
chmod +w ../
chmod +w *.gz

echo 'Done'

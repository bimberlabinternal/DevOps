#!/bin/bash

set -e
set -x

if [ -e mcc-website ];then
	rm -Rf mcc-website
fi

git clone https://github.com/bimberlabinternal/mcc-website.git

rm -Rf /usr/local/labkey/extraWebapp/*

cp mcc-website/*.html /usr/local/labkey/extraWebapp/
cp -R mcc-website/assets /usr/local/labkey/extraWebapp/

rm -Rf mcc-website



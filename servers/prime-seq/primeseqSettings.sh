#!/bin/bash
set -x
set -e

#PRIME-seq:

MAJOR=21
MINOR_FULL="3"
MINOR_SHORT=3

LKENV=$(grep ^EnvironmentFile /etc/systemd/system/labkey.service | cut -d = -f2 | sed 's/ //g')
TOMCAT_HOME=$(grep ^CATALINA_HOME $LKENV | cut -d= -f2 | sed 's/ //g')

LABKEY_HOME=/usr/local/labkey
LABKEY_USER=labkey
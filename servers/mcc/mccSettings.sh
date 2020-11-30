#!/bin/bash
set -x
set -e

#MCC:

MAJOR=20
MINOR_FULL="7"
MINOR_SHORT=7

LKENV=$(grep ^EnvironmentFile /etc/systemd/system/labkey.service | cut -d = -f2 | sed 's/ //g')
TOMCAT_HOME=$(grep ^CATALINA_HOME $LKENV | cut -d= -f2 | sed 's/ //g')

LABKEY_HOME=/usr/local/labkey
LABKEY_USER=mcclabkey
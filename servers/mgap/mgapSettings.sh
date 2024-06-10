#!/bin/bash
set -x
set -e

#mGAP:

MAJOR=24
MINOR_FULL="3"
MINOR_SHORT=$MINOR_FULL

TOMCAT_HOME=$(grep CATALINA_BASE /etc/systemd/system/labkey_server.service | cut -d = -f3 | sed 's/"//g')

LABKEY_HOME=/usr/local/labkey
LABKEY_USER=mgaplabkey

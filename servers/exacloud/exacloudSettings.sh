#!/bin/bash
set -x
set -e

#Exacloud:

MAJOR=20
MINOR_FULL="7"
MINOR_SHORT=7

LABKEY_HOME=/home/exacloud/lustre1/prime-seq/src
LABKEY_USER=labkey_submit

JAVA_HOME=/home/groups/prime-seq/exacloud/java/current
JAVA=${JAVA_HOME}/bin/java
LK_SRC_DIR=${LABKEY_HOME}
TOMCAT_HOME=/home/exacloud/lustre1/prime-seq/tomcat

SKIP_INSTALL=1
#!/bin/bash
set -x
set -e

#Exacloud:

MAJOR=20
MINOR_FULL="11"
MINOR_SHORT=1

LABKEY_HOME=/home/exacloud/gscratch/prime-seq/src
LABKEY_USER=labkey_submit

JAVA_HOME=/home/exacloud/gscratch/prime-seq/java/current
JAVA=${JAVA_HOME}/bin/java
LK_SRC_DIR=${LABKEY_HOME}
TOMCAT_HOME=/home/exacloud/gscratch/prime-seq/tomcat

SKIP_INSTALL=1
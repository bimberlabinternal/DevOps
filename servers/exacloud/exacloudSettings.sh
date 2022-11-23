#!/bin/bash
set -x
set -e

#Exacloud:

MAJOR=22
MINOR_FULL="11"
MINOR_SHORT=$MINOR_FULL

LABKEY_HOME=/home/exacloud/gscratch/prime-seq/src
LABKEY_USER=labkey_submit

JAVA_HOME=/home/exacloud/gscratch/prime-seq/java/current
JAVA=${JAVA_HOME}/bin/java
LK_SRC_DIR=${LABKEY_HOME}
TOMCAT_HOME=/home/exacloud/gscratch/prime-seq/tomcat
TOOL_DIR=/home/groups/prime-seq/pipeline_tools/bin/

SKIP_INSTALL=1
#!/bin/bash
set -x
set -e

#Exacloud:

MAJOR=22
MINOR_FULL="3"
MINOR_SHORT=$MINOR_FULL

LABKEY_HOME=/home/groups/prime-seq/exacloud/src
LABKEY_USER=labkey_submit

JAVA_HOME=/home/groups/prime-seq/exacloud/java/current
JAVA=${JAVA_HOME}/bin/java
LK_SRC_DIR=${LABKEY_HOME}

TOOL_DIR=/home/groups/prime-seq/pipeline_tools/bin/

SKIP_INSTALL=1
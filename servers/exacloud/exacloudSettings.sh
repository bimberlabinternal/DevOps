#!/bin/bash
set -x
set -e

#Exacloud:

MAJOR=25
MINOR_FULL="11"
MINOR_SHORT=$MINOR_FULL

LABKEY_HOME=/home/exacloud/gscratch/prime-seq/src_arc
LABKEY_USER=labkey_submit

JAVA_HOME=/home/exacloud/gscratch/prime-seq/java/current
JAVA=${JAVA_HOME}/bin/java
LK_SRC_DIR=${LABKEY_HOME}

SKIP_INSTALL=1
KEEP_JAR=1

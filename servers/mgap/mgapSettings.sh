#!/bin/bash
set -x
set -e

#mGAP:

MAJOR=25
MINOR_FULL="7"
MINOR_SHORT=$MINOR_FULL

LABKEY_HOME=/usr/local/labkey
LABKEY_USER=mgaplabkey
SERVICE_NAME=labkey_server
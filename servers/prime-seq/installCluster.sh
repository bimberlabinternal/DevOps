#!/bin/bash

set -e
set -x

su -c 'ssh -q labkey_submit@arc "cd /home/exacloud/gscratch/prime-seq/src_arc;bash installLabkey.sh"' labkey
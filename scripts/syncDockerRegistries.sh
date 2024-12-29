#!/bin/bash

set -e

AUTHFILE=/usr/local/etc/labkey/.dockerRegistry
LOCKFILE=/var/lock/syncDockerRegistries.lock

# Check is Lock File exists, if not create it and set trap on exit
if [ ! -e $LOCKFILE ]; then
	 trap "rm -f $LOCKFILE" EXIT
else
	 echo "Lock file exists… exiting"
	 exit
fi


doSync() {
	skopeo sync --dest-authfile $AUTHFILE --src-authfile $AUTHFILE --src docker --dest docker ghcr.io/${1} hpcregistry.ohsu.edu
}

doSync "bimberlab/cellhashr:latest"
doSync "bimberlab/rira:latest"
doSync "bimberlab/nimble:latest"
doSync "bimberlabinternal/cellmembrane:latest"
doSync "bimberlabinternal/rdiscvr:latest"

touch /var/log/dockerSyncLastRun
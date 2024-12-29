#!/bin/bash

set -e

AUTHFILE=/usr/local/etc/labkey/.dockerRegistry

doSync() {
	skopeo sync --dest-authfile $AUTHFILE --src-authfile $AUTHFILE --src docker --dest docker ghcr.io/${1} hpcregistry.ohsu.edu
}

doSync "bimberlab/cellhashr:latest"
doSync "bimberlab/rira:latest"
doSync "bimberlab/nimble:latest"
doSync "bimberlabinternal/cellmembrane:latest"
doSync "bimberlabinternal/rdiscvr:latest"

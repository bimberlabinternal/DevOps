#!/bin/bash

# The purpose of this script is to checkout clean enlistment of the lab's LabKey repos and merge 
# changes into the LabKey forks of them.  The next step is to open PRs, which is currently manual.

set -e
set -x

mergeRepo() {
    SOURCE_ORG=$1
	REPO=$2
	SOURCE_BRANCH=$3

    TARGET_ORG=labkey
	TARGET_BRANCH=fb_merge_${SOURCE_BRANCH}

	WORK_DIR=${TEMP}/$REPO
	if [ -e $WORK_DIR ];then
		rm -Rf $WORK_DIR	    
	fi

	mkdir -p $WORK_DIR
	cd $WORK_DIR

	git clone -b $SOURCE_BRANCH https://github.com/${SOURCE_ORG}/${REPO}.git
	cd `basename "$REPO" .git`
	git remote add merge-dest https://github.com/${TARGET_ORG}/${REPO}.git
	git fetch merge-dest

	git checkout --no-track -b $TARGET_BRANCH merge-dest/develop

	git merge --no-ff origin/${SOURCE_BRANCH} -m "Merge "${SOURCE_BRANCH}" to develop"
	git push --set-upstream merge-dest $TARGET_BRANCH
	
	#TODO: can I automatically open a PR?
	#git request-pull merge-dest/$TARGET_BRANCH https://github.com/${TARGET_ORG}/${REPO} merge-dest/develop
}

SOURCE_BRANCH=discvr-19.3
mergeRepo 'BimberLab' 'DiscvrLabKeyModules' $SOURCE_BRANCH
mergeRepo 'BimberLabInternal' 'LabDevKitModules' $SOURCE_BRANCH
mergeRepo 'BimberLabInternal' 'BimberLabKeyModules' $SOURCE_BRANCH


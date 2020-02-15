#!/bin/sh

# The purpose of this script is to checkout clean enlistment of a given repo, merge 
# changes into the LabKey fork, and automatically open a PR.

set -e
set -x

SOURCE_ORG=$1
if [ -z $SOURCE_ORG ];then
	echo 'Must provide SOURCE_ORG'
	exit 1
fi

REPO=$2
if [ -z $REPO ];then
	echo 'Must provide REPO'
	exit 1
fi

SOURCE_BRANCH=$3
if [ -z $SOURCE_BRANCH ];then
	echo 'Must provide SOURCE_BRANCH'
	exit 1
fi

#Allow this to be overridden by environment
if [ -z $TARGET_ORG ];then
	TARGET_ORG=labkey
fi

STAGING_BRANCH=fb_merge_${SOURCE_BRANCH}
DESTINATION_BRANCH=develop

echo "REPO: $REPO"
echo "SOURCE_ORG: $SOURCE_ORG"
echo "SOURCE_BRANCH: $SOURCE_BRANCH"
echo "TARGET_ORG: $TARGET_ORG"
echo "STAGING_BRANCH: $STAGING_BRANCH"
echo "DESTINATION_BRANCH: $DESTINATION_BRANCH"
echo "PR_REVIEWERS: $PR_REVIEWERS"

git clone -b $SOURCE_BRANCH https://$GITHUB_TOKEN@github.com/${SOURCE_ORG}/${REPO}.git
cd `basename "$REPO" .git`

git config user.email "${GITHUB_EMAIL}"
git remote add merge-dest https://$GITHUB_TOKEN@github.com/${TARGET_ORG}/${REPO}.git
git fetch merge-dest

# Note, if staging exists simply merge changes into it
STAGING_EXISTS=`git branch -r --list "merge-dest/${STAGING_BRANCH}" | wc -l`
if [ $STAGING_EXISTS == 0 ];then
	echo "Staging branch does not exist, creating and merging"
	git checkout --no-track -b $STAGING_BRANCH merge-dest/${DESTINATION_BRANCH}
	git merge --no-ff origin/${SOURCE_BRANCH} -m "Merge "${SOURCE_BRANCH}" to ${DESTINATION_BRANCH}"

	#Determine if we actually have differences:
	GIT_COMMAND="git cherry -v merge-dest/$DESTINATION_BRANCH $SOURCE_BRANCH"	
	$GIT_COMMAND
	NEW_COMMITS=`$GIT_COMMAND | wc -l `
	if [ $NEW_COMMITS == 0 ];then
		echo 'There are no new commits, aborting'
		exit 0
	fi

	if [ ! -z $DRY_RUN ];then
		echo "Dry run only, aborting before push"
		exit 0
	fi

	git push --set-upstream merge-dest $STAGING_BRANCH

	REVIEWER_ARGS=
	if [ ! -z $PR_REVIEWERS ];then
		REVIEWER_ARGS="-r "$PR_REVIEWERS
	fi


	hub pull-request \
		--base ${TARGET_ORG}:${DESTINATION_BRANCH} \
		--head ${TARGET_ORG}:${STAGING_BRANCH} \
		$REVIEWER_ARGS \
		-m "Merge "${SOURCE_BRANCH}" to ${DESTINATION_BRANCH}, automatically created"

else
	echo "Staging branch exists, merging into it and assuming PR exists"
	git fetch merge-dest
	git checkout -b $STAGING_BRANCH merge-dest/$STAGING_BRANCH
	git merge --ff-only origin/${SOURCE_BRANCH}
	
	if [ ! -z $DRY_RUN ];then
		echo "Dry run only, aborting before push"
		exit 0
	fi
	
	git push -u merge-dest
fi
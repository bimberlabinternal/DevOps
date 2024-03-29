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
	TARGET_ORG=LabKey
fi

if [ -z $DESTINATION_BRANCH ];then
	DESTINATION_BRANCH=develop
fi

VERSION=`echo $SOURCE_BRANCH | sed 's/discvr-//'`
DEST_VERSION=`echo $DESTINATION_BRANCH | sed 's/discvr-//'`

if [ $DESTINATION_BRANCH != 'develop' ];then
	STAGING_BRANCH=${DEST_VERSION}_fb_merge
else
	STAGING_BRANCH=fb_merge_${VERSION}_to_develop
fi

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

NEW_COMMITS=`git cherry -v merge-dest/$DESTINATION_BRANCH origin/$SOURCE_BRANCH | wc -l `
if [ $NEW_COMMITS != 0 ];then
	git branch --force $STAGING_BRANCH --no-track merge-dest/${DESTINATION_BRANCH}
	git checkout $STAGING_BRANCH
	git merge --no-ff origin/${SOURCE_BRANCH} -m "Merge "${SOURCE_BRANCH}" to ${DESTINATION_BRANCH}"
	
	# Check whether staging branch exists and if so whether it had any changes made directly to it
	BRANCH_EXISTS=$(git ls-remote --heads merge-dest $STAGING_BRANCH | wc -l)
	if [ "$BRANCH_EXISTS" != "0" ];then
		PREVIOUS_CHANGES=`git cherry -v $STAGING_BRANCH merge-dest/$STAGING_BRANCH | wc -l `
		if [ $PREVIOUS_CHANGES != 0 ];then
			# Re-apply changes from previous staging branch
			git checkout -b previous_staging --no-track merge-dest/$STAGING_BRANCH
			git rebase $STAGING_BRANCH
			git checkout $STAGING_BRANCH
			git merge --ff-only previous_staging
		fi
	fi
	
	if [ ! -z $DRY_RUN ];then
		echo "Dry run only, aborting before push"
		exit 0
	fi
	
	git push --force -u merge-dest $STAGING_BRANCH

	PR_EXISTS=`hub pr list --base ${TARGET_ORG}:${DESTINATION_BRANCH} --head ${TARGET_ORG}:${STAGING_BRANCH} | wc -l`
	if [ $PR_EXISTS == 0 ]; then
		# Create pull request
		REVIEWER_ARGS=
		if [ ! -z $PR_REVIEWERS ];then
			REVIEWER_ARGS="-r "$PR_REVIEWERS
		fi

		hub pull-request \
			--base ${TARGET_ORG}:${DESTINATION_BRANCH} \
			--head ${TARGET_ORG}:${STAGING_BRANCH} \
			$REVIEWER_ARGS \
			-m "Merge "${SOURCE_BRANCH}" to ${DESTINATION_BRANCH}"
	else
		echo 'PR already exists, will not create'
	fi
else
	echo 'No new commits, will not merge'
fi
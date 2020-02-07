#!/bin/sh
# Adapted from: https://github.com/repo-sync/github-sync

set -e
set -x

SOURCE_REPO=$1
SOURCE_BRANCH=$2
DESTINATION_BRANCH=$3
DESTINATION_REPO=$4

if [ -z $DESTINATION_REPO ];then
	DESTINATION_REPO=$GITHUB_REPOSITORY
fi

if ! echo $SOURCE_REPO | grep '.git'
then
  if [[ -n "$SSH_PRIVATE_KEY" ]]
  then
    SOURCE_REPO="git@github.com:${SOURCE_REPO}.git"
    GIT_SSH_COMMAND="ssh -v"
  else
    SOURCE_REPO="https://github.com/${SOURCE_REPO}.git"
  fi
fi
if ! echo $DESTINATION_REPO | grep '.git'
then
  if [[ -n "$SSH_PRIVATE_KEY" ]]
  then
    DESTINATION_REPO="git@github.com:${DESTINATION_REPO}.git"
    GIT_SSH_COMMAND="ssh -v"
  else
    DESTINATION_REPO="https://github.com/${DESTINATION_REPO}.git"
  fi
fi

echo "SOURCE=$SOURCE_REPO:$SOURCE_BRANCH"
echo "DESTINATION=$DESTINATION_REPO:$DESTINATION_BRANCH"

git clone "$DESTINATION_REPO" && cd `basename "$DESTINATION_REPO" .git`
git remote add source "$SOURCE_REPO"

git checkout ${DESTINATION_BRANCH}
git fetch source

#git merge --ff-only source/${SOURCE_BRANCH}
#git push
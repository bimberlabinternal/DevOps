#!/bin/bash
# Adapted from: https://github.com/repo-sync/github-sync

set -e

SOURCE_REPO=$1
if [ -z $SOURCE_REPO ];then
	echo 'Source SOURCE_REPO provided'
	exit 1
fi

SOURCE_PREFIX=$2
if [ -z $SOURCE_PREFIX ];then
	echo 'Source SOURCE_PREFIX provided'
	exit 1
fi

DESTINATION_REPO=$3
if [ -z $DESTINATION_REPO ];then
	DESTINATION_REPO=$GITHUB_REPOSITORY
fi

DESTINATION_PREFIX=$4
if [ -z $DESTINATION_PREFIX ];then
	echo 'Source DESTINATION_PREFIX provided'
	exit 1
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
    DESTINATION_REPO="https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/${DESTINATION_REPO}.git"
  fi
fi

echo "SOURCE=$SOURCE_REPO"
echo "SOURCE_PREFIX=$SOURCE_PREFIX"
echo "DESTINATION=$DESTINATION_REPO"
echo "DESTINATION_PREFIX=$DESTINATION_PREFIX"

git clone "$DESTINATION_REPO" 
cd `basename "$DESTINATION_REPO" .git`
git remote add source "$SOURCE_REPO"
git fetch source

REMOTES=( $(git branch -r --list "*${SOURCE_PREFIX}*" | grep -v SNAPSHOT | sed 's/source\///g') )
LATEST_LOCAL=`git branch -a --list "origin/${DESTINATION_PREFIX}*" | sed 's/remotes\/origin\///g' | sort -r | head -n 1 | awk '{ sub(/^[ ]+/, ""); print }' | awk '{ sub(/[ ]+$/, ""); print }'`

for BRANCH in "${REMOTES[@]}"
do
	LOCAL_NAME=`echo $BRANCH | sed "s/"${SOURCE_PREFIX}"/"${DESTINATION_PREFIX}"/g"`
	if [ $LOCAL_NAME == $LATEST_LOCAL ];then
		echo 'Branch already exists, will not create: '$BRANCH
		continue
	fi
	
	LATEST=`echo -e "$LOCAL_NAME\n$LATEST_LOCAL" | sort -V | tail -n 1`	
	if [ $LATEST != $LATEST_LOCAL ];then
		echo 'Branch will be created: '$BRANCH' -> '$LOCAL_NAME
		git checkout -b ${LOCAL_NAME} --no-track source/${BRANCH}
		git push -u origin ${LOCAL_NAME}
	else
		echo 'Branch version lower than highest existing, will not create: '$BRANCH
	fi
done
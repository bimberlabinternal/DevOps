#!/bin/ash

set -e
set -x
set -u

# Allows override of settings
if [ -e buildSettings.sh ];then
	source buildSettings.sh
fi

BRANCH_NAME=${GITHUB_REF##*/}
BASE_BRANCH_NAME=${GITHUB_BASE_REF##*/}

# For PRs, this refers to the target
if [ ! -z $BASE_BRANCH_NAME ];then
	echo 'Using base branch as branch of record: '$BASE_BRANCH_NAME
	BRANCH_NAME=$BASE_BRANCH_NAME
fi

TAG_NAME=
if [[ ! -v GITHUB_EVENT_NAME ]];then
  echo 'Event: '$GITHUB_EVENT_NAME
	if [[ $GITHUB_EVENT_NAME == 'release' ]];then
		TAG_NAME=$BRANCH_NAME	
	fi
fi

if [[ ! -v GENERATE_DIST ]];then
	GENERATE_DIST=0
fi

if [[ ! -v TAG_NAME ]];then
	GENERATE_DIST=1
fi

GH_CREDENTIALS=
if [[ -v GITHUB_TOKEN ]];then
	GH_CREDENTIALS="${GITHUB_TOKEN}@"
fi

DEPTH_ARG="--depth 1"
if [[ -v NO_SHALLOW ]];then
	DEPTH_ARG=
fi

BASE_VERSION=`echo $BRANCH_NAME | grep -E -o '[0-9\.]{4,8}' || echo 'develop'`

if [ $BASE_VERSION == 'develop' ];then
	BASE_VERSION_SHORT='develop'
else
	BASE_VERSION_SHORT=`echo $BASE_VERSION | awk -F. '{ print $1"."$2 }'`
fi

echo "Base version inferred from branch: "$BASE_VERSION
echo "Short base version inferred from branch: "$BASE_VERSION_SHORT
echo "GENERATE_DIST: $GENERATE_DIST"
date +%F" "%T

#Determine a unique build dir, based on where we pull from:
BASEDIR=$HOME"/labkey_build/"$BASE_VERSION
if [ ! -e $BASEDIR ];then
	mkdir -p $BASEDIR
fi
cd $BASEDIR

function identifyBranch {
	GIT_ORG=$1
	REPONAME=$2

	#First try based on Tag, if present
	if [ ! -z $TAG_NAME ];then
		BRANCH_EXISTS=$(git ls-remote --tags https://${GH_CREDENTIALS}github.com/${GIT_ORG}/${REPONAME}.git ${TAG_NAME} | wc -l)
		if [ "$BRANCH_EXISTS" != "0" ];then
			BRANCH=$TAG_NAME
			echo 'Branch found, using '$BRANCH
			return
		fi
	fi

	# Then try branch of same name:
	BRANCH_EXISTS=$(git ls-remote --heads https://${GH_CREDENTIALS}github.com/${GIT_ORG}/${REPONAME}.git ${BRANCH_NAME} | wc -l)
	if [ "$BRANCH_EXISTS" != "0" ];then
		BRANCH=$BRANCH_NAME
		echo 'Branch found, using '$BRANCH
		return
	fi

	# Otherwise discvr
	TO_TEST='discvr-'$BASE_VERSION_SHORT
	if [ $TO_TEST != $BRANCH_NAME ];then
		BRANCH_EXISTS=$(git ls-remote --heads https://${GH_CREDENTIALS}github.com/${GIT_ORG}/${REPONAME}.git ${TO_TEST} | wc -l)
		if [ "$BRANCH_EXISTS" != "0" ];then
			BRANCH=$TO_TEST
			echo 'Branch found, using '$BRANCH
			return
		fi
	fi

	# Otherwise release
	TO_TEST='release'${BASE_VERSION_SHORT}-SNAPSHOT
	if [ $TO_TEST != $BRANCH_NAME ];then
		BRANCH_EXISTS=$(git ls-remote --heads https://${GH_CREDENTIALS}github.com/${GIT_ORG}/${REPONAME}.git ${TO_TEST} | wc -l)
		if [ "$BRANCH_EXISTS" != "0" ];then
			BRANCH=$TO_TEST
			echo 'Branch found, using '$BRANCH
			return
		fi
	fi

	echo 'Branch not found, using default: develop'
	BRANCH='develop'
}

function cloneGit {
	GIT_ORG=$1
	REPONAME=$2
	BRANCH=$3

	echo "Repo: "${REPONAME}", using branch: "$BRANCH

	BASE=/server/modules/
	if [[ $# -gt 3 ]] ; then
		BASE=$4
	fi

	TARGET_DIR=${SERVER_ROOT}${BASE}${REPONAME}
	GIT_URL=https://${GH_CREDENTIALS}github.com/${GIT_ORG}/${REPONAME}.git
	if [ ! -e $TARGET_DIR ];then
		cd ${SERVER_ROOT}${BASE}
		git clone $DEPTH_ARG -b $BRANCH $GIT_URL
	else
		cd $TARGET_DIR
		git fetch origin
		git reset --hard HEAD
		git clean -f -d
		git checkout -f $BRANCH
		git reset --hard HEAD
		git clean -f -d
		git pull origin $BRANCH
	fi
}

cd $BASEDIR

SERVER_ROOT=${BASEDIR}
identifyBranch Labkey server
LK_BRANCH=$BRANCH
cloneGit Labkey server $LK_BRANCH /
SERVER_ROOT=${BASEDIR}/server

export RELEASE_NAME=`grep -e 'labkeyVersion=' ${SERVER_ROOT}/gradle.properties | sed 's/labkeyVersion=//'`
echo "Release name: "$RELEASE_NAME

# Labkey/Platform
identifyBranch Labkey platform
LK_BRANCH=$BRANCH
cloneGit Labkey platform $LK_BRANCH

# Labkey/distributions
if [ $GENERATE_DIST == 1 ];then
	mkdir -p ${SERVER_ROOT}/distributions/discvr
	wget -O ${SERVER_ROOT}/distributions/discvr/build.gradle https://raw.githubusercontent.com/bimberlabinternal/DevOps/refs/heads/master/githubActions/discvr-build/distributions/discvr/build.gradle
	wget -O ${SERVER_ROOT}/distributions/discvr/gradle.properties https://raw.githubusercontent.com/bimberlabinternal/DevOps/refs/heads/master/githubActions/discvr-build/distributions/discvr/gradle.properties
fi

# BimberLab/DiscvrLabKeyModules
identifyBranch BimberLab DiscvrLabKeyModules
cloneGit BimberLab DiscvrLabKeyModules $BRANCH

# BimberLabInternal/LabDevKitModules
identifyBranch BimberLabInternal LabDevKitModules
cloneGit BimberLabInternal LabDevKitModules $BRANCH

# BimberLabInternal/BimberLabKeyModules
identifyBranch BimberLabInternal BimberLabKeyModules
cloneGit BimberLabInternal BimberLabKeyModules $BRANCH

# Labkey/ehrModules. Only retain EHR and Viral_Load_Assay
cloneGit Labkey ehrModules $LK_BRANCH

# Labkey/onprcEHRModules. Only retain GeneticsCore
cloneGit Labkey onprcEHRModules $LK_BRANCH

cd $SERVER_ROOT
echo 'Git clone complete'
date +%F" "%T

# Modify gradle config:
echo "BuildUtils.includeModules(this.settings, rootDir, [BuildUtils.SERVER_MODULES_DIR], ['ehr_billing', 'EHR_ComplianceDB', 'HormoneAssay', 'ONPRC_EHR_ComplianceDB', 'extscheduler', 'mergesync', 'ogasync', 'onprc_billing', 'onprc_billingpublic', 'onprc_ehr', 'onprc_reports', 'onprc_ssu', 'sla', 'treatmentETL'], true)" >> settings.gradle

# Note: this is the location of the checked out project, set up by github actions. 
# -v "/home/runner/work/_temp/_github_home":"/github/home"
DIST_DIR=/github/home/lkDist
if [ -e $DIST_DIR ];then
	rm -Rf $DIST_DIR;
fi
mkdir -p $DIST_DIR;

cd $SERVER_ROOT

echo 'Starting build'
date +%F" "%T

GRADLE_OPTS=-Xmx2048m

# This should force download of release snapshots from artifactory
GRADLE_RELEASE=$RELEASE_NAME
if [ $BASE_VERSION_SHORT != 'develop' ];then
	GRADLE_RELEASE=${BASE_VERSION_SHORT}-SNAPSHOT
fi

# In 24.11 the name of the distribution was updated to use underscore rather than hyphen:
LOWEST_UPDATED_BRANCH=24.11
LOWER_VERSION=`echo -e "${BASE_VERSION_SHORT}\n${LOWEST_UPDATED_BRANCH}" | sort -V | head -n1`
if [[ $BASE_VERSION == 'develop' || $LOWER_VERSION == $LOWEST_UPDATED_BRANCH ]] ;then
	PRIME_SEQ_DIST=prime_seq
else
	PRIME_SEQ_DIST=prime-seq
fi

ARTIFACTORY_SETTINGS=
if [[ -v ARTIFACTORY_USER ]];then
	ARTIFACTORY_SETTINGS="-Partifactory_user=${ARTIFACTORY_USER} -Partifactory_password=${ARTIFACTORY_PASSWORD}"
else
	echo "ARTIFACTORY_USER not supplied"
fi

# Cleanup:
./gradlew cleanNodeModules

./gradlew \
	--parallel $ARTIFACTORY_SETTINGS \
	-PuseEmbeddedTomcat \
	-PdeployMode=prod \
	stageApp

echo 'stageApp Complete'
date +%F" "%T

if [ $GENERATE_DIST == 1 ];then
	cd $SERVER_ROOT
	
	./gradlew \
		--parallel $ARTIFACTORY_SETTINGS \
		-PdeployMode=prod \
		-PuseEmbeddedTomcat \
		-PmoduleSet=distributions \
		:distributions:discvr:dist

	mv ./dist/discvr $DIST_DIR

	echo 'dist Complete'
	date +%F" "%T
	
	echo "Renaming artifact for release"
	mv $DIST_DIR/discvr/*.gz $DIST_DIR/discvr/DISCVR-${BASE_VERSION}.installer.tar.gz
	
	# Set tag now, in case we publish a latest release downstream
	cd $SERVER_ROOT/server/modules/DiscvrLabKeyModules
	
	git config --global user.email "noreply@github.com"
	git tag -fa "latest" -m "Create latest tag"
fi

echo $RELEASE_NAME > ${DIST_DIR}/release.txt

#!/bin/bash

set -e
set -x

# Allows override of settings
if [ -e travisSettings.sh ];then
	source travisSettings.sh
fi

BASE_VERSION=`echo $TRAVIS_BRANCH | grep -E -o '[0-9\.]{4,8}' || echo 'develop'`

if [ $BASE_VERSION == 'develop' ];then
	BASE_VERSION_SHORT='develop'
else
	BASE_VERSION_SHORT=`echo $BASE_VERSION | awk '{ print substr($0,1,4) }'`
fi

echo "Base version inferred from branch: "$BASE_VERSION
echo "Short base version inferred from branch: "$BASE_VERSION_SHORT
date +%F" "%T
pwd

#Determine a unique build dir, based on where we pull from:
BASEDIR=$HOME"/labkey_build/"$BASE_VERSION
if [ ! -e $BASEDIR ];then
	mkdir -p $BASEDIR
fi
cd $BASEDIR

#Note: gradle's :server:stopTomcat will fail without tomcat.home set
export CATALINA_HOME=$HOME"/tomcat9"

# Note: when travis setups up a branch, it uses the cache from the default branch, which means the cache can hold builds from other branches:
for dir in ${HOME}/labkey_build/*
do
	if [[ $dir != $BASEDIR ]];then
		echo "Removing old build dir: "$dir
		rm -Rf $dir
	fi
done

# Download primary SVN repo
if [ $BASE_VERSION == 'develop' ];then
	SVN_URL=https://svn.mgt.labkey.host/stedi/trunk
	SVN_DIR=${BASEDIR}/trunk
else
	SVN_URL=https://svn.mgt.labkey.host/stedi/branches/release${BASE_VERSION_SHORT}-SNAPSHOT
	SVN_DIR=${BASEDIR}/release${BASE_VERSION_SHORT}-SNAPSHOT
fi

if [ -e $SVN_DIR ];then
	rm -Rf $SVN_DIR
fi

mkdir -p $SVN_DIR
cd $BASEDIR
svn co $SVN_URL

export RELEASE_NAME=`grep -e 'labkeyVersion=' ${SVN_DIR}/gradle.properties | sed 's/labkeyVersion=//'`
echo "Release name: "$RELEASE_NAME

function identifyBranch {
	GIT_ORG=$1
	REPONAME=$2

	#First try based on Tag, if present
	if [ ! -z $TRAVIS_TAG ];then
		BRANCH_EXISTS=$(git ls-remote --heads https://${GH_TOKEN}@github.com/${GIT_ORG}/${REPONAME}.git ${TRAVIS_TAG} | wc -l)
		if [ "$BRANCH_EXISTS" != "0" ];then
			BRANCH=$TRAVIS_TAG
			echo 'Branch found, using '$BRANCH
			return
		fi
	fi

	# Then try branch of same name:
	BRANCH_EXISTS=$(git ls-remote --heads https://${GH_TOKEN}@github.com/${GIT_ORG}/${REPONAME}.git ${TRAVIS_BRANCH} | wc -l)
	if [ "$BRANCH_EXISTS" != "0" ];then
		BRANCH=$TRAVIS_BRANCH
		echo 'Branch found, using '$BRANCH
		return
	fi

	# Otherwise discvr
	TO_TEST='discvr-'$BASE_VERSION_SHORT
	if [ $TO_TEST != $TRAVIS_BRANCH ];then
		BRANCH_EXISTS=$(git ls-remote --heads https://${GH_TOKEN}@github.com/${GIT_ORG}/${REPONAME}.git ${TO_TEST} | wc -l)
		if [ "$BRANCH_EXISTS" != "0" ];then
			BRANCH=$TO_TEST
			echo 'Branch found, using '$BRANCH
			return
		fi
	fi

	# Otherwise release
	TO_TEST='release'${BASE_VERSION_SHORT}-SNAPSHOT
	if [ $TO_TEST != $TRAVIS_BRANCH ];then
		BRANCH_EXISTS=$(git ls-remote --heads https://${GH_TOKEN}@github.com/${GIT_ORG}/${REPONAME}.git ${TO_TEST} | wc -l)
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
	if [ -n "$4" ];then
		BASE=$4
	fi

	TARGET_DIR=${SVN_DIR}${BASE}${REPONAME}
	GIT_URL=https://${GH_TOKEN}@github.com/${GIT_ORG}/${REPONAME}.git
	if [ ! -e $TARGET_DIR ];then
		cd ${SVN_DIR}${BASE}
		git clone -b $BRANCH $GIT_URL
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

# Labkey/Platform
identifyBranch Labkey platform
LK_BRANCH=$BRANCH
cloneGit Labkey platform $LK_BRANCH

# Labkey/distributions. Note: user does not have right run ls-remote, so infer from platform
BRANCH=`echo $LK_BRANCH | sed 's/-SNAPSHOT//'`
cloneGit Labkey distributions $BRANCH /

# Labkey/dataintegration. Note: user does not have right run ls-remote, so infer from platform
# NOTE: this should be downloaded from the artifactory
# cloneGit Labkey dataintegration $LK_BRANCH /server/optionalModules/

# BimberLab/DiscvrLabKeyModules
identifyBranch BimberLab DiscvrLabKeyModules
cloneGit BimberLab DiscvrLabKeyModules $BRANCH

# BimberLabInternal/LabDevKitModules
identifyBranch BimberLabInternal LabDevKitModules
cloneGit BimberLabInternal LabDevKitModules $BRANCH

# BimberLabInternal/BimberLabKeyModules
identifyBranch BimberLabInternal BimberLabKeyModules
cloneGit BimberLabInternal BimberLabKeyModules $BRANCH

# Labkey/ehrModules.  Only retain Viral_Load_Assay
cloneGit Labkey ehrModules $LK_BRANCH

cd $SVN_DIR
echo 'Git clone complete'
date +%F" "%T

# Modify gradle config:
echo "BuildUtils.includeModules(this.settings, rootDir, [BuildUtils.SERVER_MODULES_DIR], ['ehr', 'ehr_billing', 'EHR_ComplianceDB'], true)" >> settings.gradle

#make distribution
DIST_DIR=${TRAVIS_BUILD_DIR}/lkDist
if [ ! -e $DIST_DIR ];then
	mkdir -p $DIST_DIR ];
fi

if [ ! -e ${CATALINA_HOME}/bin/bootstrap.jar ];then
	if [ -e $$CATALINA_HOME ];then
		rm -Rf $CATALINA_HOME
	fi

	mkdir -p $CATALINA_HOME
	cd $CATALINA_HOME
	curl --insecure -O https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.35/bin/apache-tomcat-9.0.35.tar.gz	
	tar xzvf apache-tomcat-9*tar.gz -C $CATALINA_HOME --strip-components=1
	rm apache-tomcat-9*tar.gz
fi

cd $SVN_DIR

echo 'Starting build'
date +%F" "%T

INCLUDE_VCS=
if [ ! -z $TRAVIS_TAG ];then
	INCLUDE_VCS="-PincludeVcs"
fi

GRADLE_OPTS=-Xmx2048m

./gradlew \
	-Dorg.gradle.daemon=false \
	--parallel \
	-Dtomcat.home=$CATALINA_HOME \
	cleanNodeModules cleanBuild cleanDeploy
	
echo 'clean Complete'
date +%F" "%T

# This should force download of release snapshots from artifactory
GRADLE_RELEASE=$RELEASE_NAME
if [ $BASE_VERSION_SHORT != 'develop' ];then
	GRADLE_RELEASE=${BASE_VERSION_SHORT}-SNAPSHOT
fi

./gradlew \
	-Dorg.gradle.daemon=false \
	--parallel \
	-Dtomcat.home=$CATALINA_HOME \
	$INCLUDE_VCS \
	-Partifactory_user=${ARTIFACTORY_USER} \
	-Partifactory_password=${ARTIFACTORY_PASSWORD} \
	-PlabkeyVersion=${GRADLE_RELEASE} \
	-PdeployMode=prod \
	deployApp

echo 'deployApp Complete'
date +%F" "%T

#Rename artifacts if a public release:
if [ ! -z $TRAVIS_TAG ];then
	./gradlew \
		-Dorg.gradle.daemon=false \
		--parallel \
		-Dtomcat.home=$CATALINA_HOME \
		$INCLUDE_VCS \
		-Partifactory_user=${ARTIFACTORY_USER} \
		-Partifactory_password=${ARTIFACTORY_PASSWORD} \
		-PlabkeyVersion=${GRADLE_RELEASE} \
		-PdeployMode=prod \
		-PmoduleSet=distributions \
		-PdistDir=$DIST_DIR \
		:distributions:discvr:dist :distributions:discvr_modules:dist :distributions:prime-seq-modules:dist

	mv ./dist/* $DIST_DIR

	echo 'dist Complete'
	date +%F" "%T

	echo "Renaming artifact for release"
	mv $DIST_DIR/discvr/*.gz $DIST_DIR/discvr/DISVCR-${BASE_VERSION}.installer.tar.gz
	mv $DIST_DIR/discvr_modules/*.zip $DIST_DIR/discvr/DISVCR-${BASE_VERSION}.modules.zip
fi

echo $RELEASE_NAME > ${TRAVIS_BUILD_DIR}/release.txt

echo 'Cleaning build dir to reduce cache'
rm -Rf ${SVN_DIR}/build/deploy

# Double check the contents of the cache
du -s -h  $HOME/labkey_build/*
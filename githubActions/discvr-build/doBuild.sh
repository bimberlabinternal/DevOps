#!/bin/ash

set -e
set -x
set -u

# Allows override of settings
if [ -e buildSettings.sh ];then
	source buildSettings.sh
fi

BRANCH_NAME=${GITHUB_REF##*/}

TAG_NAME=
if [[ ! -v GITHUB_EVENT_NAME ]];then
	if [[ $GITHUB_EVENT_NAME == 'release' ]];then
		TAG_NAME=$BRANCH_NAME	
	fi
fi

GH_CREDENTIALS=
if [[ -v GITHUB_TOKEN ]];then
	GH_CREDENTIALS="${GITHUB_TOKEN}@"
fi

BASE_VERSION=`echo $BRANCH_NAME | grep -E -o '[0-9\.]{4,8}' || echo 'develop'`

if [ $BASE_VERSION == 'develop' ];then
	BASE_VERSION_SHORT='develop'
else
	BASE_VERSION_SHORT=`echo $BASE_VERSION | awk -F. '{ print $1"."$2 }'`
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

cd $BASEDIR

# Labkey/server. Note: for 20.11 and lower, use SVN. Otherwise git:
LOWEST_GIT=20.11
LOWER_VERSION=`echo -e "${BASE_VERSION_SHORT}\n${LOWEST_GIT}" | sort -V | head -n1`
if [[ $BASE_VERSION == 'develop' || $LOWER_VERSION == $LOWEST_GIT ]] ;then
	SERVER_ROOT=${BASEDIR}
	identifyBranch Labkey server
	LK_BRANCH=$BRANCH
	cloneGit Labkey server $LK_BRANCH /
	SERVER_ROOT=${BASEDIR}/server
else
	SVN_URL=https://svn.mgt.labkey.host/stedi/branches/release${BASE_VERSION_SHORT}-SNAPSHOT
	SERVER_ROOT=${BASEDIR}/release${BASE_VERSION_SHORT}-SNAPSHOT
	
	SVN_EXISTS=`svn list $SVN_URL 2>&1 >/dev/null | grep -e 'non-existent' | wc -l`
	if [ "$SVN_EXISTS" != "0" ];then
		echo 'SVN branch not found, using trunk'
		SVN_URL=https://svn.mgt.labkey.host/stedi/trunk
		SERVER_ROOT=${BASEDIR}/trunk
	fi
	
	if [ -e $SERVER_ROOT ];then
		rm -Rf $SERVER_ROOT
	fi

	mkdir -p $SERVER_ROOT
	svn co $SVN_URL
fi

export RELEASE_NAME=`grep -e 'labkeyVersion=' ${SERVER_ROOT}/gradle.properties | sed 's/labkeyVersion=//'`
echo "Release name: "$RELEASE_NAME

# Labkey/Platform
identifyBranch Labkey platform
LK_BRANCH=$BRANCH
cloneGit Labkey platform $LK_BRANCH

# Labkey/distributions
identifyBranch Labkey distributions
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

cd $SERVER_ROOT
echo 'Git clone complete'
date +%F" "%T

# Modify gradle config:
echo "BuildUtils.includeModules(this.settings, rootDir, [BuildUtils.SERVER_MODULES_DIR], ['ehr', 'ehr_billing', 'EHR_ComplianceDB'], true)" >> settings.gradle

#make distribution
DIST_DIR=/lkDist
if [ ! -e $DIST_DIR ];then
	mkdir -p $DIST_DIR;
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

cd $SERVER_ROOT

echo 'Starting build'
date +%F" "%T

INCLUDE_VCS=
if [ ! -z $TAG_NAME ];then
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

ARTIFACTORY_SETTINGS=
if [[ -v ARTIFACTORY_USER ]];then
	ARTIFACTORY_SETTINGS="-Partifactory_user=${ARTIFACTORY_USER} -Partifactory_password=${ARTIFACTORY_PASSWORD}"
else
	echo "ARTIFACTORY_USER not supplied"
fi

./gradlew \
	-Dorg.gradle.daemon=false \
	--parallel \
	-Dtomcat.home=$CATALINA_HOME \
	$INCLUDE_VCS \
	$ARTIFACTORY_SETTINGS \
	-PlabkeyVersion=${GRADLE_RELEASE} \
	-PdeployMode=prod \
	deployApp

echo 'deployApp Complete'
date +%F" "%T

#Rename artifacts if a public release:
if [ ! -z "$TAG_NAME" ];then
	./gradlew \
		-Dorg.gradle.daemon=false \
		--parallel \
		-Dtomcat.home=$CATALINA_HOME \
		$INCLUDE_VCS \
		$ARTIFACTORY_SETTINGS \
		-PlabkeyVersion=${GRADLE_RELEASE} \
		-PdeployMode=prod \
		-PmoduleSet=distributions \
		-PdistDir=$DIST_DIR \
		:distributions:discvr:dist :distributions:discvr_modules:dist :distributions:prime-seq-modules:dist

	mv ./dist/* $DIST_DIR

	echo 'dist Complete'
	date +%F" "%T

	echo "Renaming artifact for release"
	mv $DIST_DIR/discvr/*.gz $DIST_DIR/discvr/DISCVR-${BASE_VERSION}.installer.tar.gz
	mv $DIST_DIR/discvr_modules/*.zip $DIST_DIR/discvr/DISCVR-${BASE_VERSION}.modules.zip
fi

echo $RELEASE_NAME > release.txt

echo 'Cleaning build dir to reduce cache'
rm -Rf ${SERVER_ROOT}/build/deploy

# Double check the contents of the cache
du -s -h  $HOME/labkey_build/*

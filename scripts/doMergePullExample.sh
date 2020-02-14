#!/bin/bash

docker build -t lk-merge-pull .

mergeRepo() {
	# To auto-assign reviewers to PR:
	# -e PR_REVIEWERS='labkey-tchad'
	# To abort before commits made:
	# -e DRY_RUN=1
	# To use another org (such as for testing):
	# -e TARGET_ORG='anotherOrg'
	docker run --rm \
		-e GITHUB_EMAIL='<EMAIL>' \
		-e GITHUB_TOKEN='<TOKEN>' \
		-i lk-merge-pull \
		$1 $2 $3
}


SOURCE_BRANCH=discvr-19.3
mergeRepo 'BimberLab' 'DiscvrLabKeyModules' $SOURCE_BRANCH
mergeRepo 'BimberLabInternal' 'LabDevKitModules' $SOURCE_BRANCH
mergeRepo 'BimberLabInternal' 'BimberLabKeyModules' $SOURCE_BRANCH


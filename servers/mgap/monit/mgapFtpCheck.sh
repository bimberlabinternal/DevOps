#!/bin/bash

LOG_FILE=/var/log/mgapCurlErrors.txt

testDownload() {
	FN=$1
	CODE=`curl --silent -o /dev/null -w "%{http_code}" -I $FN`
	if [[ $CODE != "200" ]];then
	  echo "Error ${CODE}: ${FN}"
    exit 1
  fi
}

# Latest:
testDownload https://mgapdownload.ohsu.edu/latest/mGAP.Rhesus_macaque.vcf.gz
testDownload https://mgapdownload.ohsu.edu/latest/mGAP.Rhesus_macaque.vcf.gz.tbi

# Version 3.0:
testDownload https://mgapdownload.ohsu.edu/996D1E75-0762-103E-BEEA-F619086A00D2/mGap.Rhesus_macaque.v3.0.vcf.gz
testDownload https://mgapdownload.ohsu.edu/996D1E75-0762-103E-BEEA-F619086A00D2/mGap.Rhesus_macaque.v3.0.vcf.gz.tbi
testDownload https://mgapdownload.ohsu.edu/996D1E75-0762-103E-BEEA-F619086A00D2/mGap.Rhesus_macaque.v3.0.sitesOnly.vcf.gz
testDownload https://mgapdownload.ohsu.edu/996D1E75-0762-103E-BEEA-F619086A00D2/mGap.Rhesus_macaque.v3.0.sitesOnly.vcf.gz.tbi

# Genome:
testDownload https://mgapdownload.ohsu.edu/genomes/3_Mmul_10.fasta
testDownload https://mgapdownload.ohsu.edu/genomes/3_Mmul_10.fasta.fai
testDownload https://mgapdownload.ohsu.edu/genomes/3_Mmul_10.dict

# Version 2.5:
testDownload https://mgapdownload.ohsu.edu/BFE9C0C0-75F1-103C-89E5-F8F3FC868539/mGap.v2.5.vcf.gz
testDownload https://mgapdownload.ohsu.edu/BFE9C0C0-75F1-103C-89E5-F8F3FC868539/mGap.v2.5.vcf.gz.tbi
testDownload https://mgapdownload.ohsu.edu/BFE9C0C0-75F1-103C-89E5-F8F3FC868539/mGap.v2.5.sitesOnly.vcf.gz
testDownload https://mgapdownload.ohsu.edu/BFE9C0C0-75F1-103C-89E5-F8F3FC868539/mGap.v2.5.sitesOnly.vcf.gz.tbi
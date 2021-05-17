#!/bin/bash

##
## Get list of projects from ADO
## For each project, get list of repositories
## For each repo, run cloc
## Output: csv
##
## Pre-requisites: git, jq, curl, cloc-1.88.pl (https://github.com/AlDanial/cloc/releases/download/1.88/cloc-1.88.pl)
##
## Tested on Amazon EC2 linux 4.14.121-109.96.amzn2.x86_64
##

## Script param variables
# Your ADO PAT (tested with full access PAT)
ADOPAT=
# Your ADO org name
ADOORG=
# The output file name
RSFILE=./results.csv

## Script internal variables
# Project name
PROJECT=""
# Repo URL
REPO=""
# Project list count
C=0

# Init results file
echo "Project,Repo,Languages,Count" > ${RSFILE}

# Init PAT base64
B64PAT=$(printf "%s"":$ADOPAT" | base64)

# For each project
for I in $(curl -s -u :${ADOPAT} https://dev.azure.com/${ADOORG}/_apis/projects?api-version=6.0 | jq '.value[] | .name,.id' | sed -e "s/\"//g" | sed -e "s/ /_/g")
do
	# If project name
	if [ $((C%2)) -eq 0 ];
	then
		# Store project name
		echo Processing project $I;
		PROJECT=$I
	else
		# Else, process project id
		# For each repo URL
		for J in $(curl -s -u :${ADOPAT} https://dev.azure.com/${ADOORG}/${I}/_apis/git/repositories?api-version=6.0 | jq '.value[].webUrl' | sed -e "s/\"//g")
		do
			# Store repo URL
			REPO=$J
			# Calculate dir name
			CLONE_DIR=$(echo ${REPO##*/} | cut -d "." -f1)
			echo Counting repo $CLONE_DIR $REPO
			# Clone the repo
			git -c http.extraHeader="Authorization: Basic ${B64PAT}" clone ${REPO}
			# Count LOC
			./cloc-1.88.pl $CLONE_DIR | egrep "Apex Class |Apex Trigger |ASP |ASP.NET |C |C# |C++ |C/C++ Header |COBOL |Go |Groovy |HTML |Java |JavaScript |TypeScript |JSP |JSX |Kotlin |Objective-C |Perl |PHP |Python |Ruby |Scala |SQL |Swift |Visual Basic|Vuejs Component" | tr -s " " > ${CLONE_DIR}/cloc.out
			# Get language list from cloc output  
			LANG_LIST=""
			CL=0
			# For each supported language line in the cloc output file, get the count
			for L in $(cat ${CLONE_DIR}/cloc.out | cut -d " " -f1)
			do
			    # Get the language
				if [ "$CL" -gt "0" ]
				then
					LANG_LIST="${LANG_LIST} / ${L}"
				else
					LANG_LIST=${L}
					CL=$((CL+1))
				fi
			done
			CNT=0
			# Add language LOC to the total LOC
			for K in $(cat ${CLONE_DIR}/cloc.out | cut -d " " -f5)
			do
				CNT=$((CNT+K))
			done
			# Append data to the results file
			echo ${PROJECT},${CLONE_DIR},${LANG_LIST},${CNT} >> ${RSFILE}
			# Cleanup
			rm -rf $CLONE_DIR
		done
	fi
	# Increment project list count
	C=$((C+1))
done

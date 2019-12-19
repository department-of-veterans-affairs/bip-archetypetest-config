#!/bin/sh

## turn on to assist debugging ##
#export PS4='[$LINENO] '
#set -x
##

# useful variables
cwd=`pwd`
thisScript="$0"
echo $thisScript
thisFileName=gen
args="$@"
returnStatus=0
# script variables
propertiesFile="gen.properties"
overwriteExisting=-1
skipBuild=-1
originDirName="bip-archetype-config-origin"
originGroupId="gov.va.bip.origin"
genLog="$cwd/gen.log"

###   properties   ###
# required in properties file
groupId=""
artifactId=""
applicationId=""
version=""
artifactName=""
artifactNameLowerCase=""
artifactNameUpperCase=""
servicePort=""
projectNameSpacePrefix=""

################################################################################
#########################                              #########################
#########################   SCRIPT UTILITY FUNCTIONS   #########################
#########################                              #########################
################################################################################

## function to exit the script immediately ##
## arg1 (optional): exit code to use        ##
## scope: private (internal calls only)    ##
function exit_now() {
	#  1 = error from a bash command
	#  5 = invalid command line argument
	#  6 = property not allocated a value
	# 10 = project directory already exists

	exit_code=$1
	if [ -z $exit_code ]; then
		exit_code="0"
	elif [ "$exit_code" -eq "0" ]; then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
		echo " BUILD COMPLETE" 2>&1 | tee -a "$genLog"
		echo "" 2>&1 | tee -a "$genLog"
		echo " ##################################################################################" 2>&1 | tee -a "$genLog"
		echo " ## 1. Move $artifactId to a valid location in your local git repo." 2>&1 | tee -a "$genLog"
		echo " ## 2. Build and test $artifactId." 2>&1 | tee -a "$genLog"
		echo " ## 3. Use git to initialize, commit, and register with the remote repo. " 2>&1 | tee -a "$genLog"
		echo " ## SEE: https://github.com/department-of-veterans-affairs/bip-archetype-service " 2>&1 | tee -a "$genLog"
		echo " ##################################################################################" 2>&1 | tee -a "$genLog"
		echo "" 2>&1 | tee -a "$genLog"
	else
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
		echo " ***   BUILD FAILED (exit code $exit_code)   ***" 2>&1 | tee -a "$genLog"
		echo "" 2>&1 | tee -a "$genLog"
		# check exit codes
		if [ "$exit_code" -eq "1" ]; then
			echo "Command error. See output at end of $genLog"
		elif [ "$exit_code" -eq "5" ]; then
			# Invalie command line argument
			echo " ERROR: Invalid command-line argument \"-$OPTARG\" (use \"$thisScript -h\" for help) ... aborting immediately" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "6" ]; then
			# One or more properties not set
			echo " ERROR: \"$propertiesFile\" does not provide values for the following properties:" 2>&1 | tee -a "$genLog"
			echo "        $missingProperties" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "7" ]; then
			# One or more properties not set
			echo " ERROR: \"$artifactId\" project already exists ... aborting immediately" 2>&1 | tee -a "$genLog"
			echo "        Delete/move the project, or start this script with the -o option" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "10" ]; then
			# One or more properties not set
			echo " ERROR: Directory \"$artifactId\" already exists. Delete the directory " 2>&1 | tee -a "$genLog"
			echo "        or execute this generate script and properties in another directory. " 2>&1 | tee -a "$genLog"
		else
			# some unexpected error
			echo " Unexpected error code: $exit_code ... aborting immediately" 2>&1 | tee -a "$genLog"
		fi
	fi
	echo "" 2>&1 | tee -a "$genLog"
	echo " Help: \"$thisScript -h\"" 2>&1 | tee -a "$genLog"
	echo " Logs: \"$genLog\"" 2>&1 | tee -a "$genLog"
	echo "       search: \"+>> \" (script); \"sed: \" (sed); \"FAIL\" (mvn & cmd)" 2>&1 | tee -a "$genLog"
	echo "------------------------------------------------------------------------"2>&1 | tee -a "$genLog"
	# exit
	exit $exit_code
}


## function to display help             ##
## scope: private (internal calls only) ##
function show_help() {
	echo "" 2>&1 | tee -a "$genLog"
	echo "Examples:" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -h  show this help" 2>&1 | tee -a "$genLog"
	echo "  $thisScript     generate project using gen.properties file" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -s  skip (re)building the Origin source project" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -o  over-write new project if it already exists" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -so both skip build, and overwrite" 2>&1 | tee -a "$genLog"
	echo "" 2>&1 | tee -a "$genLog"
	echo "Notes:" 2>&1 | tee -a "$genLog"
	echo "* Full instructions available in development branch at:" 2>&1 | tee -a "$genLog"
	echo "  https://github.com/department-of-veterans-affairs/bip-archetype-service/" 2>&1 | tee -a "$genLog"
	echo "* A valid \"gen.properties\" file must exist in the same directory" 2>&1 | tee -a "$genLog"
	echo "  as this script." 2>&1 | tee -a "$genLog"
	echo "* It is recommended that a git credential helper be utilized to" 2>&1 | tee -a "$genLog"
	echo "  eliminate authentication requests while executing. For more info see" 2>&1 | tee -a "$genLog"
	echo "  https://help.github.com/articles/caching-your-github-password-in-git/" 2>&1 | tee -a "$genLog"
	echo "" 2>&1 | tee -a "$genLog"
	echo "" 2>&1 | tee -a "$genLog"
	# if we are showing this, force exit
	exit_now
}

## get argument options off of the command line        ##
## required parameter: array of command-line arguments ##
## scope: private (internal calls only)                ##
function get_args() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "+>> Processing command-line arguments" 2>&1 | tee -a "$genLog"

	# echo "args: \"$@\""
	#if [ "$@" -eq "" ]; then
	if [[ "$@" == "" ]]; then
		echo "+>> Using properties file \"$propertiesFile\"" 2>&1 | tee -a "$genLog"
	fi
	while getopts ":hso" opt; do
		echo "+>> previous_opt value = $previous_opt"2>&1 | tee -a "$genLog"
		echo "+>> current opt value = $opt"2>&1 | tee -a "$genLog"
		case "$opt" in
			h)
				show_help
				;;
			s)
				skipBuild=0
				echo "+>> Skipping build of Origin project" 2>&1 | tee -a "$genLog"
				;;
			o)
				# echo "+>> -o > overwrite" 2>&1 | tee -a "$genLog"
				overwriteExisting=0
				echo "+>> Existing project will be deleted and recreated if it already exists" 2>&1 | tee -a "$genLog"
				;;
			\?)
				exit_now 5
				;;
		esac
		previous_opt="$opt"
	done
	# shift $((OPTIND -1))
}

################################################################################
########################                                ########################
########################   BUSINESS UTILITY FUNCTIONS   ########################
########################                                ########################
################################################################################

## function to populate property vars from $propertiesFile ##
## arg: none                                               ##
## scope: private (internal calls only)                    ##
function read_properties() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "cd $cwd" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cd "$cwd" 2>&1 >> "$genLog"
	echo "+>> pwd = `pwd`" 2>&1 | tee -a "$genLog"

	if [ ! -f "$propertiesFile" ]; then
		echo "*** ERROR File \"$propertiesFile\" is missing. Cannot generate the project." 2>&1 | tee -a "$genLog"
		# invalid properties will be caught when validate_properties function is called
	else
		echo "" 2>&1 | tee -a "$genLog"
		echo "+>> Reading project properties declared in $propertiesFile" 2>&1 | tee -a "$genLog"

		# set up to parse property lines
		OIFS=$IFS
		IFS='='
		# read file
		# echo "△ start reading file"
		while read line
		do
			if [[ $line != *"#"* && $line != "" ]]; then
				# remove all whitespace from the line
				tuple=`echo "${line//[[:space:]]/}"`
				# get the key and value from the tuple
				theKey=$(echo "$tuple" | cut -d'=' -f 1)
				theVal=$(echo "$tuple" | cut -d'=' -f 2)
				echo "     tuple: $tuple" 2>&1 | tee -a "$genLog"

				# assigning values cannot be done using declare or eval - this is what bash reduces us to ...
				if [[ "$theKey" == "groupId" ]]; then groupId=$theVal; fi
				if [[ "$theKey" == "artifactId" ]]; then artifactId=$theVal; fi
				if [[ "$theKey" == "applicationId" ]]; then applicationId=$theVal; fi
				if [[ "$theKey" == "version" ]]; then version=$theVal; fi
				if [[ "$theKey" == "artifactName" ]]; then artifactName=$theVal; fi
				if [[ "$theKey" == "artifactNameLowerCase" ]]; then artifactNameLowerCase=$theVal; fi
				if [[ "$theKey" == "artifactNameUpperCase" ]]; then artifactNameUpperCase=$theVal; fi
				if [[ "$theKey" == "servicePort" ]]; then servicePort=$theVal; fi
				if [[ "$theKey" == "projectNameSpacePrefix" ]]; then projectNameSpacePrefix=$theVal; fi
			fi
		done < "$cwd/$propertiesFile"
		IFS=$OIFS
	fi
}

## function to validate property vars from $propertiesFile ##
## arg: none                                               ##
## scope: private (internal calls only)                    ##
function validate_properties() {
	# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "+>> Validating project properties declared in $propertiesFile" 2>&1 | tee -a "$genLog"

	missingProperties=""
	if [[ "$groupId" == "" ]]; then missingProperties+="groupId "; fi
	if [[ "$artifactId" == "" ]]; then missingProperties+=( "artifactId " ); fi
	if [[ "$applicationId" == "" ]]; then missingProperties+=( "applicationId " ); fi
	if [[ "$version" == "" ]]; then missingProperties+=( "version " ); fi
	if [[ "$artifactName" == "" ]]; then missingProperties+=( "artifactName " ); fi
	if [[ "$artifactNameLowerCase" == "" ]]; then missingProperties+=( "artifactNameLowerCase " ); fi
	if [[ "$artifactNameUpperCase" == "" ]]; then missingProperties+=( "artifactNameUpperCase " ); fi
	if [[ "$servicePort" == "" ]]; then missingProperties+=( "servicePort " ); fi
	if [[ "$projectNameSpacePrefix" == "" ]]; then missingProperties+=( "projectNameSpacePrefix " ); fi

	if [[ "$missingProperties" != "" ]]; then
		exit_now 6
	fi
}

## function to check exit status from commands ##
## arg (required): command exist status "$?"   ##
## scope: private (internal calls only)        ##
function check_exit_status() {
	returnStatus="$1"
	if [ "$returnStatus" -eq "0" ]; then
		echo "[OK]" 2>&1 | tee -a "$genLog"
	else
		exit_now "$1"
	fi
}

## function to change directories              ##
## arg (required): directory to change to      ##
## scope: private (internal calls only)        ##
function cd_to() {
	cd_dir="$1"
	echo "" 2>&1 | tee -a "$genLog"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "cd $cd_dir" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cd "$cd_dir" 2>&1 >> "$genLog"
	check_exit_status "$?"
	echo "+>> pwd = `pwd`" 2>&1 | tee -a "$genLog"
}

################################################################################
############################                        ############################
############################   BUSINESS FUNCTIONS   ############################
############################                        ############################
################################################################################

## function to (re)build the Origin project ##
## arg: none                                ##
## scope: private (internal calls only)     ##
function build_origin() {
	cd_to "$cwd/$originDirName"

	if [ "$skipBuild" -eq "0" ]; then
		echo "+>> Not building $originDirName" 2>&1 | tee -a "$genLog"
	else
		echo "+>> Building the $originDirName project" 2>&1 | tee -a "$genLog"
		echo "mvn clean install -Ddockerfile.skip=true -e -X" 2>&1 | tee -a "$genLog"
		mvn clean install -Ddockerfile.skip=true -e -X  2>&1 >> "$genLog"
		check_exit_status "$?"
	fi
}

## function to copy the origin project to a new project directory ##
## arg: none                                                      ##
## scope: private (internal calls only)                           ##
function copy_origin_project() {
	cd_to "$cwd"

	if [ -d "./$artifactId" ]; then
		if [ "$overwriteExisting" -eq "0" ]; then
			echo "+>> Over-writing existing $artifactId project" 2>&1 | tee -a "$genLog"
			echo "rm -rf $artifactId/" 2>&1 | tee -a "$genLog"
			# tee does not play well with some bash commands, so just redirect output to the log
			rm -rf "$artifactId/" 2>&1 >> "$genLog"
			check_exit_status "$?"
		else
			exit_now 7
		fi
	fi

	echo "+>> Copy $originDirName to $artifactId" 2>&1 | tee -a "$genLog"
	echo "cp -R -f ./$originDirName/ ./$artifactId/" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cp -R -f "./$originDirName/" "./$artifactId/" 2>&1 >> "$genLog"
	check_exit_status "$?"
}

## function to clean up and prepare files for new project ##
## arg: none                                              ##
## scope: private (internal calls only)                   ##
function prepare_files() {
	cd_to "$cwd/$artifactId"

	# copy the reactor (root) README for new projects
	echo "+>> Copy README.md" 2>&1 | tee -a "$genLog"
	echo "cp -fv ./archive/bip-archetype-service-newprojects-README.md ./README.md" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cp -fv "./archive/bip-archetype-service-newprojects-README.md" "./README.md" 2>&1 >> "$genLog"
	check_exit_status "$?"

	# delete the archive directory
	echo "+>> Delete archive directory" 2>&1 | tee -a "$genLog"
	echo "rm -rf ./archive" 2>&1 | tee -a "$genLog"
	rm -rf "./archive" 2>&1 >> "$genLog"
	check_exit_status "$?"

	# maven clean has proven unreliable in some scenarios,
	# so making sure all target directories are deleted
	echo "+>> Delete all target directories" 2>&1 | tee -a "$genLog"
	oldWord="target"
	find . -name "$oldWord" -depth -type d -maxdepth 4 -print | while read tmpDir; do
		echo "rm -rf $tmpDir" 2>&1 | tee -a "$genLog"
		rm -rf "$tmpDir" 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"
}

## function to rename project directories ##
## arg: none                              ##
## scope: private (internal calls only)   ##
function rename_directories() {
	cd_to "$cwd/$artifactId"

	# rename bip-origin dirs
	echo "+>> Renaming directories in place: bip-origin to $artifactId" 2>&1 | tee -a "$genLog"
	oldWord="bip-origin-config"
	find . -name "*$oldWord*" -depth -type d -maxdepth 4 -print | while read tmpDir; do
		newDir=${tmpDir//$oldWord/$artifactId}
		echo "mv -f -v $tmpDir $newDir" 2>&1 | tee -a "$genLog"
		mv -f $tmpDir $newDir 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"

	# rename origin dirs
	originGroupidAsPath=${originGroupId//\./\/}
	artifactGroupidAsPath=${groupId//\./\/}
	echo "+>> Renaming directories in place: $originGroupidAsPath to $artifactGroupidAsPath" 2>&1 | tee -a "$genLog"
	oldWord="$originGroupidAsPath"
	find . -path "*$originGroupidAsPath" -depth -type d -maxdepth 20 -print | while read tmpDir; do
		newDir=${tmpDir//$oldWord/$artifactGroupidAsPath}
		echo "mkdir -p $newDir"
		mkdir -p "$newDir"
		check_exit_status "$?"
		echo "mv -f $tmpDir/* $newDir" 2>&1 | tee -a "$genLog"
		mv -f $tmpDir/* $newDir/  2>&1 >> "$genLog"
		echo "rm -rf $tmpDir"
		rm -rf "$tmpDir"
		check_exit_status "$?"
	done; check_exit_status "$?"
	echo "+)) done"
}

## function to rename project files     ##
## arg: none                            ##
## scope: private (internal calls only) ##
function rename_files() {
	cd_to "$cwd/$artifactId"

	# rename bip-origin files
	echo "+>> Renaming files in place: bip-origin to $artifactId" 2>&1 | tee -a "$genLog"
	oldWord="bip-origin"
	find . -name "*$oldWord*" -depth -type f -maxdepth 20 -print | while read tmpFile; do
		newFile=${tmpFile//$oldWord/$applicationId}
		mv -f -v $tmpFile $newFile 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"

	# rename Origin files
	echo "+>> Renaming files in place: Origin to $artifactName" 2>&1 | tee -a "$genLog"
	oldWord="Origin"
	find . -name "*$oldWord*" -depth -type f -maxdepth 20 -print | while read tmpFile; do
		newFile=${tmpFile//$oldWord/$artifactName}
		mv -f -v $tmpFile $newFile 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"
}

## function to change text inside files  ##
## arg: none                             ##
## scope: private (internal calls only)  ##
function change_text() {
	cd_to "$cwd/$artifactId"

	#########################################################
	## NOTE sed *always* returns "0" as its exit code      ##
	##      regardless if it succeeds or not. If changes   ##
	##      are made to sed commands, you must check the   ##
	##      genarchetype.log (search "sed -i") to verify   ##
	##      that no sed error messages follow the command  ##
	## Error lines will begin with "sed: "                 ##
	#########################################################

	find . -type f -maxdepth 20 \
		! -iwholename '*.DS_Store' \
		! -iname '*.jks' \
		! -iname '*.classpath' \
		! -ipath '*.settings*' \
		| while read tmpFile; do
		## ^^^^
		## Do not include .project in the above exclusions

		# replace archetype package/groupId
		oldVal="gov.va.bip.origin"
		newVal="$groupId"
		echo "sed -i \"\" -e \'s/\'\"$oldVal\"\'/\'\"$newVal\"\'/g\' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# artifactId replacement
		oldVal="bip-origin-config"
		newVal="$artifactId"
		echo "sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# camelcase replacement
		oldVal="Origin"
		newVal="$artifactName"
		echo "sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# lowercase replacement
		oldVal="origin"
		newVal="$artifactNameLowerCase"
		echo "sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# uppercase replacement
		oldVal="ORIGIN"
		newVal="$artifactNameUpperCase"
		echo "sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
	    # projectNameSpacePrefix replacement
		oldVal="bip-project-namespace-prefix"
		newVal="$projectNameSpacePrefix"
		echo "sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
	done; check_exit_status "$?"
}

## function to build the new project    ##
## arg: none                            ##
## scope: private (internal calls only) ##
function build_new_project() {
	cd_to "$cwd/$artifactId"

	echo "+>> Building the $artifactId project" 2>&1 | tee -a "$genLog"
	echo "mvn clean package -Ddockerfile.skip=true -e -X" 2>&1 | tee -a "$genLog"
	mvn clean package -Ddockerfile.skip=true -e -X  2>&1 >> "$genLog"
	check_exit_status "$?"
}

################################################################################
#######################                                  #######################
#######################   SCRIPT EXECUTION BEGINS HERE   #######################
#######################                                  #######################
################################################################################

## output header info, get the log started ##
echo ""  2>&1 | tee "$genLog"
echo "=========================================================================" 2>&1 | tee -a "$genLog"
echo "Generate a BIP Service project" 2>&1 | tee -a "$genLog"
echo "=========================================================================" 2>&1 | tee -a "$genLog"
echo "" 2>&1 | tee -a "$genLog"

## call each function in order ##
get_args $args
read_properties
validate_properties
copy_origin_project
#prepare_files
rename_directories
rename_files
change_text

exit_now 0

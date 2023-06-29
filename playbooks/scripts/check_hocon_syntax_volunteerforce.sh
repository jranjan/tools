CAC_DIR=/Users/jyoti.ranjan/Desktop/Jyoti/Livewire/git/griddable/cac

CONFIG_DIR=$CAC_DIR/configs
SERVICE_DIR=$CONFIG_DIR/services
GRID_DIR=$CONFIG_DIR/substrates/aws/aws-prod1-useast1/coretip1/grid-config/
TAG_ROOT_DIR=$CONFIG_DIR/tags
POLICY_DIR=$CONFIG_DIR/policies
DBCONFIG_DIR=$CONFIG_DIR/dbconfigs
MODULE_DIR=$CAC_DIR/modules/config-packages

TAGS=ORG_PROD_FALCON_DP:ORG_PROD_NA70_DP
POLICIES=consumer-targetoracle-coretipprod-0.1:consumer-targetsdb-coretipprod-0.1:relay-sourceoracle-na70-0.1
DBCONFIGS=target-oracle-coretipprod:target-sdb-coretipprod:source-oracle-na70

CATCHUP=chs-cfg-1p-na70
CONSUMER=consumer-cfg-coretipshared
MANAGEMENT=managementserver-cfg-falcon-coretipshared
POLICY=policyserver-cfg-falcon-coretipshared
RELAY=relay-cfg-1P-na70
GRID=corgmigrate

PACKAGE_CATCHUP=package-catchup-aws.aws-prod1-useast1.coretip-t.medium
PACKAGE_CONSUMER=package-consumer-aws-prod1-useast1.coretip-t.medium
PACKAGE_MANAGEMENT=package-management-aws-prod1-useast1.coretip-t.medium
PACKAGE_POLICY=package-policy-aws-prod1-useast1.coretip-t.medium
PACKAGE_RELAY=package-relay-aws-prod1-useast1.coretip-t.medium

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'

function fn_check_file()
{
	printf "Checking file: %s:" $1
   	pyhocon -i $1 1> /dev/null
   	if [ "$?" != "0" ]
	then
		echo -en "${RED}"
		echo "******************************************************************************"
		printf "SCAN FOR FILE: %s : FAILED\n" $1
		echo "******************************************************************************"
	else
		echo -en "${GREEN}"
		printf "PASSED\n"
	fi
	echo -en "${NONE}"
}


function fn_check_files()
{	
	IFS=':' read -r -a files <<< "$2"
	unset IFS
	for file in "${files[@]}"
	do
		fn_check_file $1/$file.conf 
	done 
	unset IFS
}


function fn_check_directory()
{
	IFS=$'\n'
	FILES=($(find $1 -type f -name "*.conf" -follow -print))
	unset IFS
	
	echo "----------------------------------------------------------------------------"
	printf "Scanning files of directory: $s\n" $1
	printf "\t%s\n" ${FILES[@]}
	echo "----------------------------------------------------------------------------"
	for file in "${FILES[@]}"
	do
   		fn_check_file $file
	done 
}


function fn_check_multiple_directories()
{	
	IFS=':' read -r -a tagdirs <<< "$2"
	unset IFS
	echo "============================================================================"
	printf "Scanning multiple-directories:\n" 
	printf "\t%s\n" ${tagdirs[@]}
	echo "============================================================================"
	for tagd in "${tagdirs[@]}"
	do
		fn_check_directory $1/$tagd
	done 
}

echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Service name: %s\n" "Catchup"
printf "Service default directory: %s\n" $SERVICE_DIR/catchup/_defaults
fn_check_directory $SERVICE_DIR/catchup/_defaults
echo ".............................................................................."
printf "Service name: %s\n" "Catchup"
printf "Service instance directory: %s\n" $SERVICE_DIR/catchup/$CATCHUP
fn_check_directory $SERVICE_DIR/catchup/$CATCHUP
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Service name: %s\n" "Consumer"
printf "Service default directory: %s\n" $SERVICE_DIR/consumer/_defaults
fn_check_directory $SERVICE_DIR/consumer/_defaults
echo "****************************************************************************"
printf "Service name: %s\n" "Consumer"
printf "Service instance directory: %s\n" $SERVICE_DIR/consumer/_defaults
fn_check_directory $SERVICE_DIR/consumer/$CONSUMER
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Service name: %s\n" "Management Server"
printf "Service instance directory: %s\n" $SERVICE_DIR/mgmt-server/$MANAGEMENT
fn_check_directory $SERVICE_DIR/mgmt-server/$MANAGEMENT
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Service name: %s\n" "Policy Server"
printf "Service instance directory: %s\n" $SERVICE_DIR/policy-server/$POLICY
fn_check_directory $SERVICE_DIR/policy-server/$POLICY
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Service name: %s\n" "Relay"
printf "Service default directory: %s\n" $SERVICE_DIR/relay/_defaults
fn_check_directory $SERVICE_DIR/relay/_defaults
echo "****************************************************************************"
printf "Service name: %s\n" "Relay"
printf "Service instance directory: %s\n" $SERVICE_DIR/relay/$RELAY
fn_check_directory $SERVICE_DIR/relay/$RELAY
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Grid name: %s\n" "Grid"
printf "Scanning instance directory: %s\n" $GRID_DIR/$GRID
fn_check_directory $GRID_DIR/$GRID
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Entity name: %s\n" "Tags"
printf "Scanning multple-tag directory: %s\n" TAGS
fn_check_multiple_directories $TAG_ROOT_DIR $TAGS
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Entity name: %s\n" "Dbconfigs"
printf "Scanning dbconfigs: %s\n" $DBCONFIGS
fn_check_files $DBCONFIG_DIR $DBCONFIGS
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
printf "Entity name: %s\n" "Policies"
printf "Scanning policies: %s\n" $POLICIES
fn_check_files $POLICY_DIR $POLICIES
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"



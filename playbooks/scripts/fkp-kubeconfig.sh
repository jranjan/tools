#!/usr/bin/env bash

MAINTAINER_NOTE="
This script supports both the aws s3 credential fetching as well
as using pseudo api to access clusters without PCSK credentials.
Currently, the pseudo api is under a subcommand. In the future,
the aws s3 credential fetching should also be moved to a sub-
command.
Note: All Pseudo API functions are marked with the prefix
\"pseudo_api__\"
"

SCRIPT_VERSION="1.1.0"
K8S_NAMESPACE="default"
REGION="$(aws configure get region || true)"

PSEUDO_PROD_API="https://pseudo-kubeapi.sfproxy.controltelemetry.aws-esvc1-useast2.aws.sfdc.cl"
PSEUDO_NON_PROD_API="https://pseudo-kubeapi.sfproxy.core3.test1-uswest2.aws.sfdc.cl"


set -Eeuo pipefail
trap cleanup EXIT
trap bad_error SIGINT SIGTERM ERR

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [--no-color] [readonly] [-f] -s <SAM/FKP_AWS_ACCOUNT_ID> -c <CLUSTER_NAME> [-r REGION] [-n NAMESPACE]
FKP Kubectl Access Tool
Version: ${SCRIPT_VERSION}
Use this script to download a working kubeconfig file for accessing an FKP (SAM) cluster.
Use --help on the \"readonly\" subcommand to view more information about that subcommand.
Available Options:
-h, --help                Print this help and exit
-v, --verbose             Print script debug info
-f, --fkp-team-member     Skip specifying the account ID for members of the FKP team
-s, --fkp-account         AWS Account ID of the SAM account
-c, --k8s-cluster         Name of the k8s clsuter
-r, --region              Name of the AWS region, will be taken from AWS config if not provided
-n, --default-namespace   Set the default Namespace of the kube-context
--no-color                Do not color the terminal
EOF
  exit
}

pseudo_api__usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") readonly [-h] [-v] -t <FALCON_INSTANCE> -c <CLUSTER_NAME> [-n NAMESPACE] [-p PSEUDO-KUBE-API]
FKP Kubectl Access Tool -- Read Only Access
Version: ${SCRIPT_VERSION}
Use this command to access the pseudo API for access to production clusters without bastions
or PCSK credentials.
Available Options:
-h, --help                       Print this help and exit
-i, --falcon-instance            Falcon Instance
-d, --falcon-functional-domain   Falcon Functional Domain Name
-c, --k8s-cluster                Name of the k8s clsuter
-p, --pseudo-api                 Pseudo API endpoint to use
-n, --default-namespace          Set the default Namespace of the kubectx
EOF
  exit
}

pseudo_api__parse_parameters() {
  shift # removes "readonly"
  while :; do
    case "${1-}" in
    -h | --help) pseudo_api__usage ;;
    -v | --verbose) set -x ;;
    --no-color) export NO_COLOR=1 ;;
    -i | --falcon-instance)          export FALCON_INSTANCE="${2}"  ; shift;;
    -d | --falcon-functional-domain) export FUNCTIONAL_DOMAIN="${2}"; shift;;
    -p | --pseudo-api)               export PSEUDO_API_SERVER="${2}"; shift;;
    -c | --k8s-cluster)              export CLUSTER_NAME="${2}"     ; shift;;
    -n | --default-namespace)        export K8S_NAMESPACE="${2}"    ; shift;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  [[ -z "${FALCON_INSTANCE-}" ]] && die "
Missing required parameter: FALCON_INSTANCE (-i or --falcon-instance)
"
  [[ -z "${FUNCTIONAL_DOMAIN-}" ]] && die "
Missing required parameter: FUNCTIONAL_DOMAIN (-d or --falcon-functional-domain)
"
  [[ -z "${CLUSTER_NAME-}" ]] && die "
Missing required parameter: K8s Cluster Name (-c or --k8s-cluster)
Please look it up the Cluster column from https://sfdc.co/fkp-accounts
"
  return 0
}

pseudo_api__set_config() {
  FALCON_K8_CONTEXT="${FALCON_INSTANCE}-${FUNCTIONAL_DOMAIN}-${CLUSTER_NAME}"

  if [[ -z "${PSEUDO_API_SERVER-}" ]]; then
    if [[ "${FALCON_INSTANCE}" =~ .*(stage|prod|esvc).* ]]; then
      PSEUDO_API_SERVER="${PSEUDO_PROD_API}"
    else
      PSEUDO_API_SERVER="${PSEUDO_NON_PROD_API}"
    fi
  fi

  kubectl config set-credentials periscope-user --token=periscope-token &>/dev/null
  kubectl config set-cluster "${FALCON_K8_CONTEXT}" --server="${PSEUDO_API_SERVER}/${FALCON_K8_CONTEXT}" &>/dev/null
  kubectl config set-context "${FALCON_K8_CONTEXT}" --cluster="${FALCON_K8_CONTEXT}" --user=periscope-user &>/dev/null
  kubectl config use-context "${FALCON_K8_CONTEXT}" &>/dev/null
  kubectl config set-context --current --namespace="${K8S_NAMESPACE}" &>/dev/null

  msg "${GREEN}
#################################################
#################### SUCCESS ####################
#################################################
${NOFORMAT}
Setup completed for:
  Falcon Instance -------: ${FALCON_INSTANCE}
  Functional Domain -----: ${FUNCTIONAL_DOMAIN}
  Cluster ---------------: ${CLUSTER_NAME}
  Namespace -------------: ${K8S_NAMESPACE}
You can use 'kubectl -n <namespace> get pods' command to check pods
"
}

pseudo_api() {
  pseudo_api__parse_parameters $@
  setup_colors
  pseudo_api__set_config
  exit 0
}


cleanup() {
  trap - EXIT
}

bad_error() {
  trap - SIGINT SIGTERM ERR
  echo "Something went wrong. Please check all input parameters.
If that fails, contact support at #falcon-k8s-platform-support"
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}


msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) export NO_COLOR=1 ;;
    readonly) pseudo_api $@; break ;;
    -f | --fkp-team)          export SAM_AWS_ACCOUNT_ID="FKP"        ;;
    -s | --fkp-account)       export SAM_AWS_ACCOUNT_ID="${2}"; shift;;
    -c | --k8s-cluster)       export CLUSTER_NAME="${2}"      ; shift;;
    -r | --region)            export REGION="${2}"            ; shift;;
    -n | --default-namespace) export K8S_NAMESPACE="${2}"     ; shift;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  # check required params and arguments
  [[ -z "${SAM_AWS_ACCOUNT_ID-}" ]] && die "
Missing required parameter: FKP Account (-s or --fkp-account)
Please look it up under the Account Id column from https://sfdc.co/fkp-accounts
"
  [[ -z "${CLUSTER_NAME-}" ]]       && die "
Missing required parameter: K8s Cluster Name (-c or --k8s-cluster)
Please look it up the Cluster column from https://sfdc.co/fkp-accounts
"
  [[ -z "${REGION-}" ]]             && die "
Missing required information: Region (-r or --region))
Region was not provided and is not present in the AWS config.
Please look it up via the AWS Console or under the Falcon Instance (FI) column from https://sfdc.co/fkp-accounts.
Remember FI names don't have hyphens for regions, so the region for aws-prod10-apsoutheast1 is actually ap-southeast-1.
"
  # People are using FI for region and it breaks the script in a weird way.
  # Note that `us-west-2` below is irrelevant and just makes the check work regardless of the
  # `aws configure` region field being set on their machine.
  #
  # This breaks if the credentials cannot call `describe-regions`, we first check if they can access the api. If they cannot,
  # we let the user use the script without checking if it is valid.
  [[ ! "$(aws ec2 describe-regions --region us-west-2 --filters --region-names ${REGION} --output text 2>&1)" =~ .*"UnauthorizedOperation".* ]] &&
  [[ -z "$(aws ec2 describe-regions --region us-west-2 --filters --region-names ${REGION} --output text 2>/dev/null)" ]] && die "
The provided region \"${REGION}\" is not a valid AWS Region.
Please provide a valid AWS Region.
The AWS region is part of the FI name, but with hypenation;
For example, the region of aws-prod10-apsoutheast1 is ap-southeast-1.
Region names are described via the following regex,
[a-z]{2}\-[(south|north)(east|west)]\-[0-9]+
or in english
two-letter code, hyphen, cardinal direction, hyphen, number
"


  # Check if required tools are installed
  [[ -z "$(which aws)" ]] &&                   die "aws not installed, please install with command: brew install awscli"
  [[ -z "$(which kubectl)" ]] &&               die "kubectl not installed, please install with command: brew install kubectl"
  [[ -z "$(which aws-iam-authenticator)" ]] && die "aws-iam-authenticator not installed, please install with command: brew install aws-iam-authenticator"

  return 0
}

parse_params "$@"
setup_colors



# Retrieve user ID from aws sts get-caller-identity response
# We use grep to ensure that the role is aliased. This prevents
# users from using the bastion credentials, which are not aliased.
#
# Example Bastion UserId vs PCSK
#
# "AR0AZHBXCOYZMJQDRSZCN:i-04a32043e21e2a5b0"
# "AR0AZHBXCOYZMJQDRSZCN:PCSK-tim.apple@aa99718d-dead-beef-a25e-fce4c96cc847"

USER_ID=$(aws sts get-caller-identity --query UserId --output text | grep '@' | awk -F '[-@]' '{print $2}')

[[ -z "${USER_ID-}" ]] && die "Unable to resolve User ID. Please make sure you are using PCSK Credentials."


# Likely customers are not using SAM/FKP account PCSK credentials so they will want their account number to
# be different from the SAM account number
if [[ "${SAM_AWS_ACCOUNT_ID-}" == "FKP" ]]; then

  export SAM_AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

elif [[ "${SAM_AWS_ACCOUNT_ID-}" == "$(aws sts get-caller-identity --query Account --output text)" ]]; then

  msg "${RED}
#################################################
#################### WARNING ####################
#################################################
      SPECIFIED ACCOUNT ID IS IDENTICAL TO
               REQUESTED CLUSTER
      PLEASE CHECK THAT YOU HAVE THE CORRECT
         FKP/SAM ACCOUNT AND THAT YOU ARE
            USING PCSK CREDENTIALS
  ONLY FKP TEAM MEMBERS SHOULD SEE THIS MESSAGE
${NOFORMAT}"

fi


STS_CREDS="$(aws sts assume-role \
                --role-arn arn:aws:iam::${SAM_AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-eks-download-kubeconfig-role \
                --role-session-name ${USER_ID} \
                --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
                --output text 2>/dev/null || true )"

[[ -z ${STS_CREDS-} ]] && die "
Unable to assume role of: arn:aws:iam::${SAM_AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-eks-download-kubeconfig-role
This is likely due to the provided cluster: ${CLUSTER_NAME} not existing in the provided region: ${REGION}
Please look it up the Cluster column from https://sfdc.co/fkp-accounts
"

export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" ${STS_CREDS})

[[ -z $(aws eks --region ${REGION} update-kubeconfig --name ${CLUSTER_NAME} --output text &>/dev/null) ]] || die "
The provided cluster: ${CLUSTER_NAME} was not found in this region: ${REGION}
Please look it up the Cluster column from https://sfdc.co/fkp-accounts
"

kubectl config set-context --current --namespace="${K8S_NAMESPACE}" &>/dev/null


msg "${GREEN}
#################################################
#################### SUCCESS ####################
#################################################
${NOFORMAT}
Setup completed for:
  Cluster ---------------: ${CLUSTER_NAME}
  SAM/FKP AWS Account ---: ${SAM_AWS_ACCOUNT_ID}
  Region ----------------: ${REGION}
  Namespace -------------: ${K8S_NAMESPACE}
You can use 'kubectl -n <namespace> get pods' command to check the running pods
"
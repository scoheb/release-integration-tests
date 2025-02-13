#!/usr/bin/env sh

set -x

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

tmpDir=$(mktemp -d)

function error() {
    echo "$@" 1>&2
}
if [ -z "$OFFLINE_TOKEN_FILE" ]; then
  error "Error: Environment variable OFFLINE_TOKEN_FILE not specified"
  error ""
  error "- Obtain one by navigating to https://console.redhat.com/openshift/token"
  error "- copy token and save to a file"
  error "- export the path to the file in an environment variable"
  error "  % export OFFLINE_TOKEN_FILE=<location>"
  error ""
  exit 1
fi

if [ ! -f "$OFFLINE_TOKEN_FILE" ]; then
  error "Error: OFFLINE_TOKEN_FILE: ${OFFLINE_TOKEN_FILE} does not exist"
  exit 1
fi

if [ -z "${WORKSPACE}" ]; then
  error "Error: Environment variable WORKSPACE not specified"
  error ""
  error "- This should contain the name of the development/user workspace"
  error "- It should NOT contain the suffix - '-tenant'"
  error ""
  exit 1
fi

if [ -z "${TOOLCHAIN_API_URL}" ]; then
  TOOLCHAIN_API_URL=https://api-toolchain-host-operator.apps.stone-prd-host1.wdlc.p1.openshiftapps.com/workspaces
fi

WORKSPACE_TENANT=${WORKSPACE}-tenant

function prepareKubeconfigFiles() {
  offline_token=$(cat "${OFFLINE_TOKEN_FILE}")
  access_token=$( OFFLINE_TOKEN="${offline_token}" ${SCRIPTDIR}/offline-to-token.sh )
  api_server=${TOOLCHAIN_API_URL}/${WORKSPACE}

  export KUBECONFIG=${tmpDir}/kubeconfig
  touch $KUBECONFIG
  oc login --token="${access_token}" --server="${api_server}" > /dev/null 2>&1
  oc project ${WORKSPACE_TENANT}  > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    error "Error: Could not access workspace ${WORKSPACE} at ${TOOLCHAIN_API_URL}"
    exit 1
  fi
  echo "${KUBECONFIG}"
}
prepareKubeconfigFiles

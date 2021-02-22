#!/usr/bin/env bash

main() {
  init "$@"
  ensure-that-each-required-option-is-provided
  ensure-oc-client-is-logged-in-to-correct-ocp-system
  print-vars
  ensure-target-directory-exists
  prepare-pipeline
  apply-pipeline
}

usage() {
  echo "usage: deploy-pipeline.sh <options>"
  echo "where options are:"
  echo "    --application-name               applicationName              the name to give the application"
  echo "    --source-repo-git-uri            sourceRepoGitUri             the URI of the source repository"
  echo "    --openshift-url                  openshiftUrl                 the URL of the OpenShift instance"
  echo "    --jenkins-build-namespace        jenkinsBuildNamespace        the namespace where jenkins builds occur"
  echo "    --image-registry-namespace       imageRegistryNamespace       the namespace where the built image is to be placed"
  echo "    --development-namespace          developmentNamespace         the namespace of the development environment"
  echo "    --ocp-hostname-base              ocpHostnameBase              the base/suffix of the OCP hostname"
  echo "    --dry-run                                                     only print out the resources to be applied"
}

init() {
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  # PROJECT_BASE_DIR is the local directory where the code is located.
  PROJECT_BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"
  APPLICATION_NAME=
  SOURCE_REPO_GIT_URI=
  SOURCE_REPO_GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  OPENSHIFT_URL=
  JENKINS_BUILD_NAMESPACE=
  IMAGE_REGISTRY_NAMESPACE=
  DEVELOPMENT_ENVIRONMENT_NAMESPACE=
  OCP_HOSTNAME_BASE=
  DRY_RUN=FALSE
  while [ "$1" != "" ]; do
    case $1 in
      --application-name )               shift
                                         APPLICATION_NAME=$1
                                         ;;
      --source-repo-git-uri )            shift
                                         SOURCE_REPO_GIT_URI=$1
                                         ;;
      --openshift-url )                  shift
                                         OPENSHIFT_URL=$1
                                         ;;
      --jenkins-build-namespace )        shift
                                         JENKINS_BUILD_NAMESPACE=$1
                                         ;;
      --image-registry-namespace )       shift
                                         IMAGE_REGISTRY_NAMESPACE=$1
                                         ;;
      --development-namespace )          shift
                                         DEVELOPMENT_ENVIRONMENT_NAMESPACE=$1
                                         ;;
      --ocp-hostname-base )              shift
                                         OCP_HOSTNAME_BASE=$1
                                         ;;
      --dry-run )                        DRY_RUN=TRUE
                                         ;;
      * )                                echo "Error: unknown option $1"
                                         usage
                                         exit 1
    esac
    shift
  done

  # If the kickstart pipeline already exists, the current trigger secret is left as is.
  CURRENT_TRIGGER_SECRET=`oc get bc ${APPLICATION_NAME}-pipeline --namespace=${JENKINS_BUILD_NAMESPACE} --output jsonpath='{@.spec.triggers[?(@.type=="Generic")].generic.secret}'`
  echo 'CURRENT_TRIGGER_SECRET is '${CURRENT_TRIGGER_SECRET}
  if [[ "${CURRENT_TRIGGER_SECRET}" == "" ]]; then
    TRIGGER_PARAM_PART=''
  else
    TRIGGER_PARAM_PART=' --param=TRIGGER_SECRET='${CURRENT_TRIGGER_SECRET}
  fi
  echo 'TRIGGER_PARAM_PART is '${TRIGGER_PARAM_PART}
}

ensure-that-each-required-option-is-provided() {
  ERROR_MESSAGES=()
  if [ -z "$APPLICATION_NAME" ]; then
    echo "ERROR: option --application-name was not provided"
    usage
    exit 1
  fi
  if [ -z "$SOURCE_REPO_GIT_URI" ]; then
    echo "ERROR: option --source-repo-git-uri was not provided"
    usage
    exit 1
  fi
  if [ -z "$OPENSHIFT_URL" ]; then
    echo "ERROR: option --openshift-url was not provided"
    usage
    exit 1
  fi
  if [ -z "$JENKINS_BUILD_NAMESPACE" ]; then
    echo "ERROR: option --jenkins-build-namespace was not provided"
    usage
    exit 1
  fi
  if [ -z "$IMAGE_REGISTRY_NAMESPACE" ]; then
    echo "ERROR: option --image-registry-namespace was not provided"
    usage
    exit 1
  fi
  if [ -z "$DEVELOPMENT_ENVIRONMENT_NAMESPACE" ]; then
    echo "ERROR: option --development-namespace was not provided"
    usage
    exit 1
  fi
  if [ -z "${OCP_HOSTNAME_BASE}" ]; then
    echo "ERROR: option --ocp-hostname-base was not provided"
    usage
    exit 1
  fi
}

print-vars() {
  echo SCRIPT_DIR is ${SCRIPT_DIR}
  echo PROJECT_BASE_DIR is ${PROJECT_BASE_DIR}
  echo APPLICATION_NAME is ${APPLICATION_NAME}
  echo SOURCE_REPO_GIT_URI is ${SOURCE_REPO_GIT_URI}
  echo SOURCE_REPO_GIT_BRANCH is ${SOURCE_REPO_GIT_BRANCH}
  echo JENKINS_BUILD_NAMESPACE is ${JENKINS_BUILD_NAMESPACE}
  echo IMAGE_REGISTRY_NAMESPACE is ${IMAGE_REGISTRY_NAMESPACE}
  echo DEVELOPMENT_ENVIRONMENT_NAMESPACE is ${DEVELOPMENT_ENVIRONMENT_NAMESPACE}
  echo OCP_HOSTNAME_BASE is ${OCP_HOSTNAME_BASE}
  echo DRY_RUN is ${DRY_RUN}
}

ensure-oc-client-is-logged-in-to-correct-ocp-system() {
  IS_OC_LOGIN_VALID=`oc project | grep 'on server "'${OPENSHIFT_URL}'"' >/dev/null && echo 'TRUE'`
  if [[ "$IS_OC_LOGIN_VALID" == "TRUE" ]]; then
    echo "OK - logged in to correct OpenShift instance ${OPENSHIFT_URL}"
  else
    echo "ERROR - not logged in to ${OPENSHIFT_URL}"
    echo "Use 'oc login ${OPENSHIFT_URL}' to login to OpenShift"
    echo "Exiting"
    exit 1
  fi
}

ensure-target-directory-exists() {
  mkdir target >/dev/null 2>&1
}

prepare-pipeline() {
  oc process \
      --filename ${PROJECT_BASE_DIR}/cicd/resources/ocp/pipeline-template.yaml \
      --param=APPLICATION_NAME=${APPLICATION_NAME} \
      --param=SOURCE_REPO_GIT_URI=${SOURCE_REPO_GIT_URI} \
      --param=SOURCE_REPO_GIT_BRANCH=${SOURCE_REPO_GIT_BRANCH} \
      --param=IMAGE_REGISTRY_NAMESPACE=${IMAGE_REGISTRY_NAMESPACE} \
      --param=DEVELOPMENT_ENVIRONMENT_NAMESPACE=${DEVELOPMENT_ENVIRONMENT_NAMESPACE} \
      ${TRIGGER_PARAM_PART} \
    > target/pipeline.yml
}

apply-pipeline() {
  if [[ "$DRY_RUN" == "TRUE" ]]; then
    cat target/pipeline.yml
  else
    cat target/pipeline.yml \
      | oc apply \
        --namespace=${JENKINS_BUILD_NAMESPACE} \
        --filename -
  fi
}

main "$@"

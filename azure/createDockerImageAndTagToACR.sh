#!/bin/bash
###############################################################
# Author        : mukherjee.aniket@gmail.com
# Creation Date : 26.01.2020
# Dependency    : docker is installed and az cli is available
#
# Description   : This script is to create image from docker file and push to Azure container registry
# Execute like  : ./createDockerImageAndTagToACR.sh <DOCKER_FILE_LOCATION> <PROJECT_NAME> <DOCKER_REGISTRY_NAME> <SUBSCRIPTION_NAME> 
# Example       : ./createDockerImageAndTagToACR.sh nginx rundeckaks demoacr.azurecr.io demo-subs-devtest
# 
###############################################################

if [ $# -ne 2 ] || [ $# -ne 4 ];; then
  echo "Usage: ./createDockerImageAndTagToACR.sh <DOCKER_FILE_LOCATION> <PROJECT_NAME> <DOCKER_REGISTRY_NAME> <SUBSCRIPTION_NAME> "
  echo "Usage: ./createDockerImageAndTagToACR.sh nginx rundeckaks demoacr.azurecr.io demo-subs-devtest"
  echo "Note: <DOCKER_FILE_LOCATION> <PROJECT_NAME> are minimum required values, other values will be default to above sample command"
  echo "Note: <DOCKER_FILE_LOCATION> should be present in $PWD containing the Dockerfile "
  echo "Usage: ./createDockerImageAndTagToACR.sh nginx rundeckaks "
  exit 1
fi

DOCKER_FILE_LOCATION=${1:-nginx} # consideration is nginx will be the folder containing docker file in the same level of the script file
PROJECT_NAME=${2:-rundeckaks}
DOCKER_REGISTRY_NAME=${3:-demoacr.azurecr.io}
SUBSCRIPTION_NAME=${4:-demo-subs-devtest}
# TODO: check the server location
AZURE_LOGIN_DETAILS="/home/workspcae/DevCloudMgmnt/common/creds/"

DOCKER_TAG_NAME=${DOCKER_REGISTRY_NAME}/${DOCKER_FILE_LOCATION}/${PROJECT_NAME}   # TODO; add the version section : v1 or : latest

 echo -n "Image will be tagged as ${DOCKER_TAG_NAME}. Continue ? [y/N]: "
 read answ
 if [ "${answ^^*}" != "Y" ]; then
  echo "You have chosen not to continue, exiting...."
  exit 4
 fi


# check for required tools
if [ ! command -v "docker" >/dev/null 2>&1 ] ; then
  echo 'docker is not found.Please install to continue'
  exit 1
fi

if [ ! command -v "az" >/dev/null 2>&1 ] ; then
  echo 'Azure CLI is not found.Please install to continue'
  exit 2
fi

#read the properties file for details to connect to azure and docker

read_properties()
{
  #Read values from the keyvalue file
  file="$1"
  while IFS="=" read -r key value; do
    if [ -z "$value" ]; then
      echo "Keyvalue file $file : Key $key is missing value!" 
      exit
    fi
    case "$key" in
      "clientID") username="$value" ;;
      "secret") password="$value" ;;
      "tenantID") tenant="$value" ;;
    esac
  done < "$file"

}

read_properties "${AZURE_LOGIN_DETAILS}/${SUBSCRIPTION_NAME}.info"

# TODO: not sure if we really need to login to azure cloud using az cli

echo "Started building the image .."
#tag the image  as  demoacr.azurecr.io/aniket/nginx
docker build -t ${DOCKER_TAG_NAME} ./${DOCKER_FILE_LOCATION}

# authenticate docker login using above commands
#docker login demoacr.azurecr.io --username dcb7205c-54f1-4e87-b7dd-0a03a0bec070 
docker login ${DOCKER_REGISTRY_NAME} --username ${username} --password ${password} 
if [ ! ${?} -eq 0 ]; then
echo "ERROR: docker login failed ..."
exit 3 
fi
# push your image to docker registry -- demoacr.azurecr.io/aniket/nginx -- it will be tagged in the ACR as aniket/nginx 
docker push ${DOCKER_TAG_NAME} 
if [ ! ${?} -eq 0 ]; then
echo "ERROR: docker push failed ..."
exit 3 
fi

# For deletion from local system you can use below command
docker rmi ${DOCKER_TAG_NAME}

# pull your image from docker registry to make sure you can pull the image
docker pull ${DOCKER_TAG_NAME}
if [ ! ${?} -eq 0 ]; then
echo "ERROR: docker pull failed ..."
exit 3 
fi

# TODO:  further enhancement - possibility to delete -- Use azure cli command to delete the image from ACR registry
# az acr repository delete --name demoacr --image aniket/nginx:latest

# To logout demoacr.azurecr.io
docker logout ${DOCKER_REGISTRY_NAME}
if [ ! ${?} -eq 0 ]; then
echo "ERROR: docker logout failed ..."
exit 3 
fi


echo "Image created and and pushed to ACR :  ${DOCKER_REGISTRY_NAME}"

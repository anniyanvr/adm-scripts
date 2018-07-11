#!/bin/bash  
set -eu -o pipefail

DOCKER_HUB_USERNAME=${DH_UNAME}
DOCKER_HUB_PASSWORD=${DH_UPASS}
DOCKER_HUB_ORGANIZATION=${DH_ORG}
DOCKER_HUB_REPOSITORY=${DH_REPO}

SEVENDAYSAGO=$(date +%Y%m%d -d "7 days ago")

# Get Docker Hub Token
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKER_HUB_USERNAME}'", "password": "'${DOCKER_HUB_PASSWORD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# Get Tags
TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${DOCKER_HUB_ORGANIZATION}/${DOCKER_HUB_REPOSITORY}/tags/?page_size=300 | jq -r '.results|.[]|.name' | grep nightly)

for TAG in $TAGS
do
  DATE=$(echo $TAG | cut -d"-" -f2)
  if [ ! "$DATE" -gt "$SEVENDAYSAGO" ]; then
  	curl -X DELETE -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${DOCKER_HUB_ORGANIZATION}/${DOCKER_HUB_REPOSITORY}/tags/${TAG}/
  fi
done

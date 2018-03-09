#!/bin/bash -e

export CONTEXT=$1
export IMG=$2
export CURR_JOB=$3
export HUB_ORG="drydock"
export TAG_NAME="master"

set_context() {
  export RES_REPO=$CONTEXT"_"$IMG"_repo"
  export RES_REPO_COMMIT=$(shipctl get_resource_version_key "$RES_REPO" "shaData.commitSha")
  export IMAGE_NAME=$(echo $IMG | awk '{print tolower($0)}')
  export RES_IMAGE_OUT=$CONTEXT"_"$IMG"_img"
  export BLD_IMG=$HUB_ORG/$IMAGE_NAME:$TAG_NAME

  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "CONTEXT=$CONTEXT"
  echo "HUB_ORG=$HUB_ORG"
  echo "TAG_NAME=$TAG_NAME"

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_REPO_COMMIT=$RES_REPO_COMMIT"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE_OUT=$RES_IMAGE_OUT"
  echo "BLD_IMG=$BLD_IMG"
}

create_image() {
  pushd $(shipctl get_resource_state $RES_REPO)
    echo "Starting Docker build & push for $BLD_IMG"
    sudo docker build -t=$BLD_IMG --pull .
    echo "Pushing $BLD_IMG"
    sudo docker push $BLD_IMG
    echo "Completed Docker build & push for $BLD_IMG"
  popd
}

create_out_state() {
  echo "Creating a state file for $RES_IMAGE_OUT"
  shipctl post_resource_state_multi "$RES_IMAGE_OUT" \
  "versionName=$TAG_NAME \
  IMG_REPO_COMMIT_SHA=$RES_REPO_COMMIT \
  BUILD_NUMBER=$BUILD_NUMBER"

  echo "Creating a state file for $CURR_JOB"
  shipctl post_resource_state_multi "$CURR_JOB" \
  "versionName=$TAG_NAME \
  IMG_REPO_COMMIT_SHA=$RES_REPO_COMMIT"
}

main() {
  set_context
  create_image
  create_out_state
}

main

#!/bin/bash -e

##############
#### MAIN ####
##############

# Parameters
ENTERPRISE=1
STANDARD=0
EXPRESS=0
VERSION="19.3.0"
SKIPMD5=1
DOCKEROPS=""
MIN_DOCKER_VERSION="17.09"
MIN_PODMAN_VERSION="1.6.0"
DOCKERFILE="Dockerfile"

# Which Edition should be used?
if [ $((ENTERPRISE + STANDARD + EXPRESS)) -gt 1 ]; then
  usage
elif [ $ENTERPRISE -eq 1 ]; then
  EDITION="ee"
elif [ $STANDARD -eq 1 ]; then
  EDITION="se2"
elif [ $EXPRESS -eq 1 ]; then
  if [ "$VERSION" == "18.4.0" ]; then
    EDITION="xe"
    SKIPMD5=1
  elif [ "$VERSION" == "11.2.0.2" ]; then
    EDITION="xe"
    DOCKEROPS="--shm-size=1G $DOCKEROPS";
  else
    echo "Version $VERSION does not have Express Edition available.";
    exit 1;
  fi;
fi;

# Which Dockerfile should be used?
if [ "$VERSION" == "12.1.0.2" ] || [ "$VERSION" == "11.2.0.2" ] || [ "$VERSION" == "18.4.0" ]; then
  DOCKERFILE="$DOCKERFILE.$EDITION"
fi;

# Oracle Database Image Name
IMAGE_NAME="oracle-stack:$VERSION-$EDITION"

echo "=========================="
echo "DOCKER info:"
docker info
echo "=========================="

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true --squash \
       $DOCKEROPS $PROXY_SETTINGS --build-arg DB_EDITION=$EDITION \
       -t $IMAGE_NAME -f $DOCKERFILE . || {
  echo ""
  echo "ERROR: Oracle Database Docker Image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the docker build operation."
  exit 1
}

# Remove dangling images (intermitten images with tag <none>)
yes | docker image prune > /dev/null

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
echo ""

cat << EOF
  Oracle Database Docker Image for '$EDITION' version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF


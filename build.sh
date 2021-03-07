#!/bin/bash
set -euo pipefail

THIS_SCRIPT_LOCATION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

HOST_SRC_DIR=${THIS_SCRIPT_LOCATION}
HOST_OUT_DIR=${1}
DOCKERFILE_DIRECTORY=${THIS_SCRIPT_LOCATION}/dockerdev/linux

# Make sure the host output directory exists.
mkdir -p ${HOST_OUT_DIR}
HOST_OUT_DIR=$(realpath ${HOST_OUT_DIR})

RUN_COMMAND="/src/dockerdev/linux/build_in_docker.sh"

# Enable the user to override some default settings via command line parameters.
while getopts r: option
do
case "${option}"
in
# The 'r' flag lets a user specify a custom command to run the container with.
r) RUN_COMMAND=${OPTARG};;
esac
done

if [ ! -x "$(command -v docker)" ]; then
    echo "Cannot find docker in path, please install docker."
    exit 1
fi

# Make sure the Docker container image containing the build environment is
# up to date and then run the actual build command inside the container.
docker build -t aabtop_rules_qt-build-env ${DOCKERFILE_DIRECTORY}

echo "Entering container..."

docker run \
    --rm \
    -t \
    --name aabtop_rules_qt-build-env-instance \
    --mount type=bind,source=${HOST_SRC_DIR},target=/src \
    --mount type=bind,source=${HOST_OUT_DIR},target=/out \
    --mount type=volume,source=aabtop_rules_qt-bazel-cache-linux,target=/root/.cache/bazel \
    aabtop_rules_qt-build-env \
    ${RUN_COMMAND} /out

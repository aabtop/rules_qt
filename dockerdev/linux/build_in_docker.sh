#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=${SCRIPT_DIR}/../..
OUT_DIR=${1}

BUILD_CONFIG=opt

echo "In container, building..."


cd ${SRC_DIR}

bazel build //sample -c ${BUILD_CONFIG} --symlink_prefix=/bazel- --verbose_failures

tar -zch -f ${OUT_DIR}/qt_linux.tar.gz -C "$(bazel info execution_root -c ${BUILD_CONFIG})/external" aabtop_qt_build

echo Success!
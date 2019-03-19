#!/bin/bash
#
# Copyright 2019 The Abseil Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script that can be invoked to test abseil-cpp in a hermetic environment
# using a Docker image on Linux. You must have Docker installed to use this
# script.

set -euox pipefail

if [ -z ${ABSEIL_ROOT:-} ]; then
  ABSEIL_ROOT="$(realpath $(dirname ${0})/..)"
fi

if [ -z ${STD:-} ]; then
  STD="c++11 c++14 c++17"
fi

if [ -z ${COMPILATION_MODE:-} ]; then
  COMPILATION_MODE="fastbuild opt"
fi

for std in ${STD}; do
  for compilation_mode in ${COMPILATION_MODE}; do
    echo "--------------------------------------------------------------------"
    echo "Testing with --compilation_mode=${compilation_mode} and --std=${std}"

    time docker run \
      --volume="${ABSEIL_ROOT}:/abseil-cpp:ro" \
      --workdir=/abseil-cpp \
      --cap-add=SYS_PTRACE \
      --rm \
      -e CC="/opt/llvm/clang/bin/clang" \
      -e BAZEL_COMPILER="llvm" \
      -e BAZEL_CXXOPTS="-std=${std}" \
      -e CPLUS_INCLUDE_PATH="/usr/include/c++/6" \
      gcr.io/google.com/absl-177019/linux_clang-latest:20190313 \
      /usr/local/bin/bazel test ... \
        --compilation_mode=${compilation_mode} \
        --copt=-Werror \
        --define="absl=1" \
        --keep_going \
        --show_timestamps \
        --test_env="GTEST_INSTALL_FAILURE_SIGNAL_HANDLER=1" \
        --test_env="TZDIR=/abseil-cpp/absl/time/internal/cctz/testdata/zoneinfo" \
        --test_output=errors \
        --test_tag_filters=-benchmark
  done
done

#!/usr/bin/env sh

#
# Copyright (c) 2024, Sebastian Davids
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -eu

readonly base_dir="${1:-$PWD}"

# https://reproducible-builds.org/docs/source-date-epoch/
SOURCE_DATE_EPOCH=$(date +%s)
export SOURCE_DATE_EPOCH

build_and_checksums() {
  ./gradlew \
    --quiet \
    --configuration-cache \
    --no-build-cache \
    clean \
    assemble

  find . -name '*.jar' | \
    grep '/build/libs/' | \
    grep --invert-match 'javadoc' | \
    sort | \
    xargs sha256sum > "$1"
}

(
  cd "${base_dir}"

  readonly checksums_dir='.checksums'

  rm -rf "${checksums_dir}"

  mkdir -p "${checksums_dir}"

  trap 'rm -rf "${checksums_dir}"' EXIT INT QUIT TSTP

  build_and_checksums "${checksums_dir}/build-1"
  build_and_checksums "${checksums_dir}/build-2"

  diff --unified "${checksums_dir}/build-1" "${checksums_dir}/build-2"
)

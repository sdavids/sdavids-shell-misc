#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

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

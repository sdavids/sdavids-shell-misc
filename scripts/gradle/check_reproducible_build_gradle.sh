#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

if [ ! -d "${base_dir}" ]; then
  printf "The directory '%s' does not exist.\n" "${base_dir}" >&2
  exit 1
fi

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

  find . -name '*.jar' \
    | grep '/build/libs/' \
    | grep --invert-match 'javadoc' \
    | sort \
    | xargs sha256sum >"$1"
}

exit_cleanup() {
  err=$?
  trap '' EXIT INT QUIT TERM
  if [ -d "${checksums_dir}" ]; then
    rm -rf "${checksums_dir}"
  fi
  exit $err
}

sig_cleanup() {
  err=$?
  trap '' EXIT
  set +e
  (exit $err)
  exit_cleanup
}

(
  cd "${base_dir}"

  readonly checksums_dir='.checksums'

  rm -rf "${checksums_dir}"

  mkdir -p "${checksums_dir}"

  # https://unix.stackexchange.com/questions/57940/trap-int-term-exit-really-necessary/
  trap exit_cleanup EXIT
  trap sig_cleanup INT QUIT TERM

  build_and_checksums "${checksums_dir}/build-1"
  build_and_checksums "${checksums_dir}/build-2"

  diff --unified "${checksums_dir}/build-1" "${checksums_dir}/build-2"
)

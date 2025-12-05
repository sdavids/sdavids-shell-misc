#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# curl needs to be in $PATH
#   Linux:
#     sudo apt-get install curl

# java (JDK 17+) needs to be in $PATH

set -Eeu -o pipefail -o posix

# https://github.com/google/google-java-format/releases
readonly version='1.33.0'

while getopts ':v' opt; do
  case "${opt}" in
    v)
      verbose='true'
      ;;
    ?)
      echo "Usage: $0 [-v] <dir>" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

readonly verbose="${verbose:-false}"

readonly base_dir="${1:-$PWD}"

if [ -n "${GOOGLE_JAVA_FORMAT_HOME+x}" ] && [ -d "${GOOGLE_JAVA_FORMAT_HOME}" ]; then
  out_dir="${GOOGLE_JAVA_FORMAT_HOME}"
else
  if [ "$(uname)" = 'Darwin' ]; then
    out_dir="${HOME}/Library/Application Support/Google/googlejavaformat"
  fi
  if [ -n "${XDG_CACHE_HOME+x}" ]; then
    out_dir="${XDG_CACHE_HOME}/googlejavaformat"
  else
    # throw it into the Maven repository black hole
    # we put it alongside the no-deps version:
    # ~/.m2/repository/com/google/googlejavaformat
    out_dir="${HOME}/.m2/repository/com/google/googlejavaformat-all-deps"
  fi
fi
readonly out_dir

readonly jar_name="google-java-format-${version}-all-deps.jar"

readonly jar_path="${out_dir}/${jar_name}"

mkdir -p "${out_dir}"

if [ ! -f "${jar_path}" ]; then
  curl \
    --silent \
    --location \
    --remote-name \
    --output-dir "${out_dir}" \
    "https://github.com/google/google-java-format/releases/download/v${version}/${jar_name}"

  chmod -x "${jar_path}"

  if [ "$(uname)" = 'Darwin' ]; then
    xattr -rc "${jar_path}"
  fi
fi

# shellcheck disable=SC2016
cmd='java -jar "$1" --set-exit-if-changed --dry-run "$2"'
if [ "${verbose}" != 'true' ]; then
  cmd+=' >/dev/null'
fi
cmd+=';'
readonly cmd

find "${base_dir}" \
  -type f \
  -name '*.java' \
  -exec sh -c "${cmd}" shell "${jar_path}" {} +

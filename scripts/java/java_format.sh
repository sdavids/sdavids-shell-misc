#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# curl needs to be in $PATH
#   Linux:
#     sudo apt-get install curl

# java (JDK 17+) needs to be in $PATH

set -eu

# https://github.com/google/google-java-format/releases
readonly version='1.33.0'

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

find "${base_dir}" \
  -type f \
  -name '*.java' \
  -exec java -jar "${jar_path}" --replace {} \;

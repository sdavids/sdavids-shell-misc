#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# jar needs to be in $PATH
# javap needs to be in $PATH

set -eu

readonly jar="${1:?JAR_FILE is required}"

if [ -n "${2+x}" ]; then # $2 defined
  case $2 in
    '' | *[!0-9]*) # $2 not an integer
      version=1000
      ;;
    *) # $2 is a positive integer or 0
      if [ "$2" -ge 5 ]; then
        version="$2"
      else
        version=1000
      fi
      ;;
  esac
else # $2 undefined
  version=1000
fi

# https://www.oracle.com/java/technologies/javase/10-relnote-issues.html#JDK-8191510
version=$((version + 44))
readonly version

# shellcheck disable=SC2046
class_file_versions=$(
  javap \
    -verbose \
    -classpath \
    "${jar}" \
    $(
      jar -tf "${jar}" \
        | grep '\.class$' \
        | grep -E --invert-match '(module|package)-info' \
        | sed 's/\.class$//'
    ) \
    | grep -o 'major version: [4-9][0-9]' \
    | sed 's/major version: //' \
    | grep --invert-match "${version}" \
    | sort -u
)
readonly class_file_versions

if [ -z "${class_file_versions}" ]; then
  exit 0
fi

for v in ${class_file_versions}; do
  # https://www.oracle.com/java/technologies/javase/10-relnote-issues.html#JDK-8191510
  java_version=$((v - 44))
  printf 'Java Version: %2s; Class File Version: %s\n' "${java_version}" "${v}"
done

if [ "${version}" -ne 1044 ]; then
  exit 100
fi

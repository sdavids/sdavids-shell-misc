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

# javap needs to be in $PATH

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 JAR_FILE" >&2
  exit 1
fi

readonly jar="$1"

if [ -n "${2+x}" ]; then # $2 defined
  case $2 in
    ''|*[!0-9]*) # $2 not an integer
      version=1000
    ;;
    *) # $2 is a positive integer or 0
      if [ "$2" -ge 5 ]; then
        version=$2
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
      jar -tf "${jar}" | \
      grep '\.class$' | \
      grep -E --invert-match '(module|package)-info' | \
      sed 's/\.class$//'
    ) | \
  grep -o 'major version: [4-9][0-9]' | \
  sed 's/major version: //' | \
  grep --invert-match "${version}" | \
  sort -u
)
readonly class_file_versions

if [ -z "${class_file_versions}" ]; then
  exit 0
fi

for v in ${class_file_versions}; do
  # https://www.oracle.com/java/technologies/javase/10-relnote-issues.html#JDK-8191510
  java_version=$((v - 44))
  printf "Java Version: %2s; Class File Version: %s\n" "${java_version}" "${v}"
done

if [ "${version}" -ne 1044 ]; then
  exit 100
fi

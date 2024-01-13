#!/usr/bin/env bash

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

set -Eeu -o pipefail -o posix

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

readonly file="$1"
readonly echo="${2:-}"

if [ ! -f "${file}" ]; then
  echo "'${file}' does not exist" >&2
  exit 2
fi

sha="$(sha1sum "${file}")"
readonly sha

hash="$(echo "${sha}" | cut -c 1-7)"
readonly hash

filename="$(rev <<< "${file}" | cut -d '.' -f2- | rev)"
readonly filename

readonly extension="${1##*.}"

if [ "${filename}" = "${extension}" ]; then
  filename_hashed="${filename}.${hash[0]}"
else
  filename_hashed="${filename}.${hash[0]}.${extension}"
fi
readonly filename_hashed

mv "${file}" "${filename_hashed}"

if [ "${echo}" = '-e' ]; then
  echo "${filename_hashed}"
fi

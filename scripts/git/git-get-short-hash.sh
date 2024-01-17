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

cd "${base_dir}"

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
  exit 1
fi

# https://git-scm.com/docs/hash-function-transition/#_object_names
object_name_length=$(echo '' | git hash-object --stdin)
object_name_length=${#object_name_length}
# 40 (SHA-1) or 64 (SHA-256)
readonly object_name_length

if [ -n "${2+x}" ]; then # $2 defined
  case $2 in
    ''|*[!0-9]*) # $2 not an integer
      hash="$(git rev-parse --short --verify 'HEAD^{commit}')"
    ;;
    *) # $2 is a positive integer or 0
      if [ "$2" -lt 4 ]; then
        # https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreabbrev
        hash="$(git -c core.abbrev=4 rev-parse --short --verify 'HEAD^{commit}')"
      elif [ "$2" -gt "${object_name_length}" ]; then
        hash="$(git -c core.abbrev="${object_name_length}" rev-parse --short --verify 'HEAD^{commit}')"
      else
        hash="$(git -c core.abbrev="$2" rev-parse --short --verify 'HEAD^{commit}')"
      fi
    ;;
  esac
else # $2 undefined
  hash="$(git rev-parse --short --verify 'HEAD^{commit}')"
fi
readonly hash

if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
  ext=''
else
  ext='-dirty'
fi
readonly ext

printf '%s%s' "${hash}" "${ext}"

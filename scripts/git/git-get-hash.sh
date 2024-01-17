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
  exit 2
fi

if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
  ext=''
else
  ext='-dirty'
fi
readonly ext

# https://reproducible-builds.org/docs/version-information/#git-checksums
# https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreabbrev
printf '%s%s' "$(git -c core.abbrev=no rev-parse --verify 'HEAD^{commit}')" "${ext}"

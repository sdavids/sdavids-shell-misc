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

# npx needs to be in $PATH

set -eu

readonly base_dir="${1:-$PWD}"

# https://github.com/svg/svgo
# https://github.com/svg/svgo/blob/main/lib/svgo/coa.js
find "${base_dir}" -type f -name '*.svg' -exec \
  npx --yes --quiet svgo {} \
    --eol lf \
    --multipass \
    --no-color \
    --quiet \
    --output "{}.min" \;

## rename *.svg.min to *.svg
find "${base_dir}" \
  -type f \
  -name '*.svg.min' \
  -exec sh -c 'f="$1"; mv -- "$f" "${f%.svg.min}.svg"' shell {} \;

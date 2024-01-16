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

# jq needs to be in $PATH
#   Mac:
#     brew install jq
#   Linux:
#     sudo apt-get install jq

set -eu

readonly base_dir="${1:-$PWD}"

find "${base_dir}" \
  -type f \
  -name '*.json' \
  -exec sh -c 'mv "$1" "$1.tmp"; jq -c . "$1.tmp" > "$1"; rm "$1.tmp"' shell {} \;

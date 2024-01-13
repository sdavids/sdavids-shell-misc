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

# zstd needs to be in $PATH
# https://chromestatus.com/feature/6186023867908096
#   Mac:
#     brew install zstd
#   Linux:
#     sudo apt install zstd

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "'$1' does not exist" >&2
  exit 2
fi

# https://man.archlinux.org/man/zstd.1
zstd "$1" --ultra -22 -foq "$1.zst"

# set the creation/modification time to the original file's
touch -c -r "$1" "$1.zst"

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

# jpegoptim needs to be in $PATH
#   Mac:
#     brew install jpegoptim
#   Linux:
#     sudo apt-get install jpegoptim

set -eu

readonly base_dir="${1:-$PWD}"

# https://man.archlinux.org/man/jpegoptim.1
find "${base_dir}" -type f -name '*.jpg' -o -name '*.jpeg' | xargs \
  jpegoptim --quiet --max=80 --force --preserve --preserve-perms --strip-all

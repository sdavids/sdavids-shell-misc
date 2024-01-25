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

# optipng
#   Mac:
#     brew install optipng
#   Linux:
#     sudo apt-get install optipng

# oxipng
#   Mac:
#     brew install oxipng
#   Linux:
#     https://github.com/shssoichiro/oxipng/issues/69

set -eu

readonly base_dir="${1:-$PWD}"

# https://man.archlinux.org/man/optipng.1
if command -v optipng 1>/dev/null; then
  find "${base_dir}" \
    -type f \
    -name '*.png' \
    -exec optipng -quiet -o5 -preserve {} \;
fi

# https://github.com/shssoichiro/oxipng
if command -v  1>/dev/null; then
  oxipng --quiet --opt 4 --strip all --alpha --preserve --recursive "${base_dir}"
fi

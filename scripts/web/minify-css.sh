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

# https://lightningcss.dev/minification.html
# https://lightningcss.dev/transpilation.html#cli
find "${base_dir}" -type f -name '*.css' -exec \
  npx --yes --quiet lightningcss-cli \
   --browserslist \
   --minify \
   --output-file "{}.min" \
   {} \;

# rename *.min.css to *.css
find "${base_dir}" \
  -type f \
  -name '*.css.min' \
  -exec sh -c 'f="$1"; mv -- "$f" "${f%.css.min}.css"' shell {} \;

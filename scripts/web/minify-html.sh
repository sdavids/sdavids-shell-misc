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

# https://www.npmjs.com/package/html-minifier-terser#options-quick-reference
find "${base_dir}" -type f -name '*.html' -exec \
  npx --yes --quiet html-minifier-terser {} \
    --collapse-boolean-attributes \
    --collapse-whitespace \
    --collapse-inline-tag-whitespace \
    --decode-entities \
    --minify-css \
    --quote-character \" \
    --remove-comments \
    --remove-empty-attributes \
    --remove-redundant-attributes \
    --remove-script-type-attributes \
    --remove-style-link-type-attributes \
    --sort-attributes \
    --sort-class-name \
    --use-short-doctype \
    -o "{}.min" \;

# rename *.html.min to *.html
find "${base_dir}" \
  -type f \
  -name '*.html.min' \
  -exec sh -c 'f="$1"; mv -- "$f" "${f%.html.min}.html"' shell {} \;

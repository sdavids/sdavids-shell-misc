#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

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

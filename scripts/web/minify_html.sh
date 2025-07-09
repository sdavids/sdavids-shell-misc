#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# npx or pnpm needs to be in $PATH
# https://docs.npmjs.com/downloading-and-installing-node-js-and-npm
# https://pnpm.io/installation

set -eu

readonly base_dir="${1:-$PWD}"

if command -v pnpm >/dev/null 2>&1; then
  # https://www.npmjs.com/package/html-minifier-terser#options-quick-reference
  find "${base_dir}" -type f -name '*.html' -exec \
    pnpm --silent dlx html-minifier-terser {} \
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
    -o "{}.tmp" \;
elif command -v npx >/dev/null 2>&1; then
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
    -o "{}.tmp" \;
fi

# rename *.html.tmp to *.html
find "${base_dir}" \
  -type f \
  -name '*.html.tmp' \
  -exec sh -c 'f="$1"; mv -- "$f" "${f%.html.tmp}.html"' shell {} \;

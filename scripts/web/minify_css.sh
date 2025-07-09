#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# npx or pnpm needs to be in $PATH
# https://docs.npmjs.com/downloading-and-installing-node-js-and-npm
# https://pnpm.io/installation

set -eu

readonly base_dir="${1:-$PWD}"

if command -v pnpm >/dev/null 2>&1; then
  # https://lightningcss.dev/minification.html
  # https://lightningcss.dev/transpilation.html#cli
  find "${base_dir}" -type f -name '*.css' -exec \
    pnpm --silent dlx lightningcss-cli \
    --browserslist \
    --minify \
    --output-file "{}.tmp" \
    {} \;
elif command -v npx >/dev/null 2>&1; then
  # https://lightningcss.dev/minification.html
  # https://lightningcss.dev/transpilation.html#cli
  find "${base_dir}" -type f -name '*.css' -exec \
    npx --yes --quiet lightningcss-cli \
    --browserslist \
    --minify \
    --output-file "{}.tmp" \
    {} \;
fi

# rename *.css.tmp to *.css
find "${base_dir}" \
  -type f \
  -name '*.css.tmp' \
  -exec sh -c 'f="$1"; mv -- "$f" "${f%.css.tmp}.css"' shell {} \;

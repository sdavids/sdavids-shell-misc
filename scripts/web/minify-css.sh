#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

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

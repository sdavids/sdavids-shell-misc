#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# npx or pnpm needs to be in $PATH
# https://docs.npmjs.com/downloading-and-installing-node-js-and-npm
# https://pnpm.io/installation

set -eu

readonly base_dir="${1:-$PWD}"

if command -v pnpm >/dev/null 2>&1; then
  # https://github.com/svg/svgo
  # https://github.com/svg/svgo/blob/main/lib/svgo/coa.js
  find "${base_dir}" -type f -name '*.svg' -exec \
    pnpm --silent dlx svgo {} \
    --eol lf \
    --multipass \
    --quiet \
    --output "{}.tmp" \;
elif command -v npx >/dev/null 2>&1; then
  # https://github.com/svg/svgo
  # https://github.com/svg/svgo/blob/main/lib/svgo/coa.js
  find "${base_dir}" -type f -name '*.svg' -exec \
    npx --yes --quiet svgo {} \
    --eol lf \
    --multipass \
    --quiet \
    --output "{}.tmp" \;
fi

# rename *.svg.tmp to *.svg
find "${base_dir}" \
  -type f \
  -name '*.svg.tmp' \
  -exec sh -c 'f="$1"; mv -- "$f" "${f%.svg.tmp}.svg"' shell {} \;

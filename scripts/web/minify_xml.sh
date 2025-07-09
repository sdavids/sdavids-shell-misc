#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# npx or pnpm needs to be in $PATH
# https://docs.npmjs.com/downloading-and-installing-node-js-and-npm
# https://pnpm.io/installation

set -eu

readonly base_dir="${1:-$PWD}"

if command -v pnpm >/dev/null 2>&1; then
  # https://www.npmjs.com/package/minify-xml#options
  find "${base_dir}" -type f -name '*.xml' -exec \
    pnpm --silent dlx minify-xml {} \
    --remove-schema-location-attributes \
    --in-place \;
elif command -v npx >/dev/null 2>&1; then
  # https://www.npmjs.com/package/minify-xml#options
  find "${base_dir}" -type f -name '*.xml' -exec \
    npx --yes --quiet minify-xml {} \
    --remove-schema-location-attributes \
    --in-place \;
fi

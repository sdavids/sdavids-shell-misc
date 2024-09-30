#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# npx needs to be in $PATH

set -eu

readonly base_dir="${1:-$PWD}"

# https://www.npmjs.com/package/minify-xml#options
find "${base_dir}" -type f -name '*.xml' -exec \
  npx --yes --quiet minify-xml {} \
  --remove-schema-location-attributes \
  --in-place \;

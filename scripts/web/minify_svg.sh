#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# npx needs to be in $PATH

set -eu

readonly base_dir="${1:-$PWD}"

# https://github.com/svg/svgo
# https://github.com/svg/svgo/blob/main/lib/svgo/coa.js
find "${base_dir}" -type f -name '*.svg' -exec \
  npx --yes --quiet svgo {} \
  --eol lf \
  --multipass \
  --no-color \
  --quiet \
  --output "{}.tmp" \;

# rename *.svg.tmp to *.svg
find "${base_dir}" \
  -type f \
  -name '*.svg.tmp' \
  -exec sh -c 'f="$1"; mv -- "$f" "${f%.svg.tmp}.svg"' shell {} \;

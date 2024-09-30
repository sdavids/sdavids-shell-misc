#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

readonly file="${base_dir}/robots.txt"

if [ "$(uname)" = 'Darwin' ]; then
  # commented lines
  sed -i '' '/^[@#]/d' "${file}"
  # empty lines
  sed -i '' '/^[[:space:]]*$/d' "${file}"
else
  # commented lines
  sed -i '/^[@#]/d' "${file}"
  # empty lines
  sed -i '/^[[:space:]]*$/d' "${file}"
fi

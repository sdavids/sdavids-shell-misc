#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# jq needs to be in $PATH
#   Mac:
#     brew install jq
#   Linux:
#     sudo apt-get install jq

set -eu

readonly base_dir="${1:-$PWD}"

find "${base_dir}" \
  -type f \
  -name '*.json' \
  -exec sh -c 'mv "$1" "$1.tmp"; jq -c . "$1.tmp" > "$1"; rm "$1.tmp"' shell {} \;

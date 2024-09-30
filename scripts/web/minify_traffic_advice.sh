#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# jq needs to be in $PATH
#   Mac:
#     brew install jq
#   Linux:
#     sudo apt-get install jq

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

readonly file="$1"

if [ ! -f "${file}" ]; then
  echo "'${file}' does not exist" >&2
  exit 2
fi

readonly tmp_file="${file}.tmp"

mv "${file}" "${tmp_file}"
jq -c . "${tmp_file}" >"${file}"
rm "${tmp_file}"

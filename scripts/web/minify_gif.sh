#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# gifsicle needs to be in $PATH
#   Mac:
#     brew install gifsicle
#   Linux:
#     sudo apt-get install gifsicle

set -eu

readonly base_dir="${1:-$PWD}"

# https://man.archlinux.org/man/gifsicle.1
find "${base_dir}" \
  -type f \
  -name '*.gif' \
  -exec sh -c 'mv "$1" "$1.tmp"; gifsicle --optimize=3 --lossy=80 --no-warnings --colors 256 "$1.tmp" -o "$1"; rm "$1.tmp"' shell {} \;

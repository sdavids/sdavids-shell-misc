#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# optipng
#   Mac:
#     brew install optipng
#   Linux:
#     sudo apt-get install optipng

# oxipng
#   Mac:
#     brew install oxipng
#   Linux:
#     https://github.com/shssoichiro/oxipng/issues/69

set -eu

readonly base_dir="${1:-$PWD}"

# https://man.archlinux.org/man/optipng.1
if command -v optipng 1>/dev/null; then
  find "${base_dir}" \
    -type f \
    -name '*.png' \
    -exec optipng -quiet -o5 -preserve {} \;
fi

# https://github.com/shssoichiro/oxipng
if command -v oxipng 1>/dev/null; then
  oxipng --quiet --opt 4 --strip all --alpha --preserve --recursive "${base_dir}"
fi

#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# jpegoptim needs to be in $PATH
#   Mac:
#     brew install jpegoptim
#   Linux:
#     sudo apt-get install jpegoptim

set -eu

readonly base_dir="${1:-$PWD}"

# https://man.archlinux.org/man/jpegoptim.1
find "${base_dir}" -type f -name '*.jpg' -o -name '*.jpeg' | xargs \
  jpegoptim --quiet --max=80 --force --preserve --preserve-perms --strip-all

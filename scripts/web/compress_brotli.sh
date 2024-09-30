#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# brotli needs to be in $PATH
# https://web.dev/uses-text-compression/
# https://developers.google.com/speed/webp/download
#   Mac:
#     brew install brotli
#   Linux:
#     sudo apt-get install brotli

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "'$1' does not exist" >&2
  exit 2
fi

# https://man.archlinux.org/man/brotli.1
brotli "$1" -fo "$1.br"

# set the creation/modification time to the original file's
touch -c -r "$1" "$1.br"

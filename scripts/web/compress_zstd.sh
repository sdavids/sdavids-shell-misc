#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# zstd needs to be in $PATH
# https://chromestatus.com/feature/6186023867908096
#   Mac:
#     brew install zstd
#   Linux:
#     sudo apt-get install zstd

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "'$1' does not exist" >&2
  exit 2
fi

# https://man.archlinux.org/man/zstd.1
zstd "$1" --ultra -22 -foq "$1.zst"

# set the creation/modification time to the original file's
touch -c -r "$1" "$1.zst"

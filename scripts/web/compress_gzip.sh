#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# gzip needs to be in $PATH
#   Mac:
#     brew install gzip
#   Linux:
#     sudo apt-get install gzip

set -eu

if [ -z "$*" ]; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "'$1' does not exist" >&2
  exit 2
fi

# https://man.archlinux.org/man/gzip.1
gzip -9fk "$1"

# set the creation/modification time to the original file's
touch -c -r "$1" "$1.gz"

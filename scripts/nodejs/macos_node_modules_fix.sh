#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

if [ "$(uname)" != 'Darwin' ]; then
  exit 0
fi

# https://stackoverflow.com/a/3915420
# https://stackoverflow.com/questions/3915040/how-to-obtain-the-absolute-path-of-a-file-via-shell-bash-zsh-sh#comment100267041_3915420
command -v realpath >/dev/null 2>&1 || realpath() {
  if [ -h "$1" ]; then
    # shellcheck disable=SC2012
    ls -ld "$1" | awk '{print $11}'
  else
    echo "$(
      cd "$(dirname -- "$1")" >/dev/null
      pwd -P
    )/$(basename -- "$1")"
  fi
}

base_dir="$(realpath "${1:-$PWD}")"
readonly base_dir

fix_node_modules() {
  # https://apple.stackexchange.com/questions/25779/on-os-x-what-files-are-excluded-by-rule-from-a-time-machine-backup
  xattr -w com.apple.metadata:com_apple_backup_excludeItem com.apple.backupd "$1"
  # https://apple.stackexchange.com/a/258791
  touch "$1/.metadata_never_index"
}
export -f fix_node_modules

find "${base_dir}" -type d -name 'node_modules' -exec sh -c 'fix_node_modules "$0";' {} \;

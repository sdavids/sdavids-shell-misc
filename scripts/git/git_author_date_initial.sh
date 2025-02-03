#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

readonly file="${2:-}"

if [ ! -d "${base_dir}" ]; then
  printf "The directory '%s' does not exist.\n" "${base_dir}" >&2
  exit 1
fi

(
  cd "${base_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    echo "'${base_dir}' is not a git repository" >&2
    exit 2
  fi

  if [ -n "${file}" ]; then
    printf '%s %s\n' "$(git --no-pager log --diff-filter=A --follow --format=%aI -- "${file}" | tail -n 1)" "${file}"
  else
    git ls-files | while IFS= read -r f; do
      printf '%s %s\n' "$(git --no-pager log --diff-filter=A --follow --format=%aI -- "${f}" | tail -n 1)" "${f}"
    done
  fi
)

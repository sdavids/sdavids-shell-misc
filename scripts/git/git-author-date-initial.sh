#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

readonly file="${2:-}"

cd "${base_dir}"

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
  echo "'${base_dir}' is not a git repository" >&2
  exit 1
fi

if [ -n "${file}" ]; then
  printf "%s %s\n" "$(git --no-pager log --diff-filter=A --follow --format=%aI -- "${file}" | tail -n 1)" "${file}"
else
  # shellcheck disable=SC2016
  git ls-files | xargs -I {} sh -c 'printf "%s %s\n" "$(git --no-pager log --diff-filter=A --follow --format=%aI -- "{}" | tail -n 1)" {}'
fi

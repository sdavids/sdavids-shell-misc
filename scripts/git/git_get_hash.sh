#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

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

  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    ext=''
  else
    ext='-dirty'
  fi
  readonly ext

  # https://reproducible-builds.org/docs/version-information/#git-checksums
  # https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreabbrev
  printf '%s%s' "$(git -c core.abbrev=no rev-parse --verify 'HEAD^{commit}')" "${ext}"
)

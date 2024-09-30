#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly base_dir="${1:-$PWD}"

(
  cd "${base_dir}"

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
    echo "'${base_dir}' is not a git repository" >&2
    exit 1
  fi

  # https://git-scm.com/docs/hash-function-transition/#_object_names
  object_name_length=$(echo '' | git hash-object --stdin)
  object_name_length=${#object_name_length}
  # 40 (SHA-1) or 64 (SHA-256)
  readonly object_name_length

  if [ -n "${2+x}" ]; then # $2 defined
    case $2 in
      '' | *[!0-9]*) # $2 not an integer
        hash="$(git rev-parse --short --verify 'HEAD^{commit}')"
        ;;
      *) # $2 is a positive integer or 0
        if [ "$2" -lt 4 ]; then
          # https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreabbrev
          hash="$(git -c core.abbrev=4 rev-parse --short --verify 'HEAD^{commit}')"
        elif [ "$2" -gt "${object_name_length}" ]; then
          hash="$(git -c core.abbrev="${object_name_length}" rev-parse --short --verify 'HEAD^{commit}')"
        else
          hash="$(git -c core.abbrev="$2" rev-parse --short --verify 'HEAD^{commit}')"
        fi
        ;;
    esac
  else # $2 undefined
    hash="$(git rev-parse --short --verify 'HEAD^{commit}')"
  fi
  readonly hash

  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    ext=''
  else
    ext='-dirty'
  fi
  readonly ext

  printf '%s%s' "${hash}" "${ext}"
)

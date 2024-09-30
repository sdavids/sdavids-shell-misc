#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly id="${1:?ID is required}"

if [ -n "${2+x}" ]; then # $2 defined
  case $2 in
    '' | *[!0-9]*) # $2 is not a positive integer or 0
      echo "'$2' is not a positive integer or 0" >&2
      exit 1
      ;;
    *) # $2 is a positive integer or 0
      count="$2"
      ;;
  esac
else # $2 undefined
  count='INF'
fi
readonly count

if [ -n "${COUNTER_DIR+x}" ] && [ -d "${COUNTER_DIR}" ]; then
  counter_dir="${COUNTER_DIR}"
elif [ -n "${XDG_RUNTIME_DIR+x}" ] && [ -d "${XDG_RUNTIME_DIR}" ]; then
  counter_dir="${XDG_RUNTIME_DIR}"
elif [ -n "${TMPDIR+x}" ] && [ -d "${TMPDIR}" ]; then
  counter_dir="${TMPDIR}"
else
  counter_dir="$(dirname -- "$(mktemp -u)")"
fi
readonly counter_dir

readonly counter_path="${counter_dir}/counter-${id}"
readonly counter_lock_path="${counter_path}.lock"

tries=0

# wrap in loop for concurrent counter file updates
while true; do
  # atomically create counter file
  # https://serverfault.com/a/774138
  set +e -o noclobber
  # shellcheck disable=SC2188
  { >"${counter_lock_path}"; } 1>/dev/null 2>/dev/null

  # shellcheck disable=SC2181
  if [ $? -eq 0 ]; then # lock file could be created
    set -e +o noclobber

    if [ ! -f "${counter_path}" ]; then
      value='0'
    else
      value="$(cat "${counter_path}")"
    fi

    if [ "${count}" != 'INF' ]; then
      if [ "${count}" -le '0' ] || [ "${value}" -ge "${count}" ]; then
        rm -f "${counter_path}" "${counter_lock_path}"
        exit 0
      fi
    fi

    # shellcheck disable=SC2003
    value=$(expr "${value}" + 1)

    printf '%s' "${value}" >"${counter_path}"

    rm -f "${counter_lock_path}"

    break
  else # lock file already exists; wait for our turn
    tries=$((tries + 1))

    if [ $tries -eq 5 ]; then
      echo "waiting on lock file ${counter_lock_path}" >&2
      tries=0
    fi

    set -e +o noclobber

    sleep 1
  fi
done

printf '%s' "${value}"

exit 100
